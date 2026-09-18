#!/usr/bin/env python3
"""Corner overlay: live map of the tracked route's buses approaching one stop."""
import json
import os
import threading
import time
import urllib.request

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Shumate", "1.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell as LayerShell, Shumate  # noqa: E402

API = os.environ["MIAMI_BUS_API"]
KEY = os.environ["MIAMI_BUS_KEY"]
ROUTE = os.environ["ROUTE_ID"]
DIR = os.environ["DIR"]
STOP = int(os.environ["STOP_ID"])
NOTIFY_MIN = int(os.environ.get("NOTIFY_MINUTES", "10"))
VEHICLES = f"vehicles?routeId={ROUTE}&mapMode=bus&track=NO&curLatitude=0&curLongitude=0"
POLL = 10
MAX_AGE = 30 * 60
MAX_MISSES = 3

CSS = b"""
.bus-overlay { background: alpha(#1e1e2e, 0.94); color: #cdd6f4; border-radius: 12px; }
.bus-header { padding: 8px 10px; font-weight: bold; }
.bus-eta { padding: 0 10px 8px; font-family: monospace; }
.marker-stop { background: #f38ba8; border: 2px solid white; border-radius: 99px; min-width: 10px; min-height: 10px; }
.marker-bus { background: #f9e2af; color: #1e1e2e; border-radius: 6px; padding: 1px 4px; font-weight: bold; font-size: 11px; }
.marker-bus-other { background: alpha(#f9e2af, 0.5); border-radius: 6px; padding: 1px 3px; font-size: 11px; }
"""


def api(path):
    # the county WAF 403s Python-urllib's default User-Agent
    req = urllib.request.Request(f"{API}/{path}", headers={"x-api-key": KEY, "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def stop_info():
    stops = api(f"routestops?routeID={ROUTE}&directionId={DIR}")
    return next(s for s in stops if s["StopID"] == STOP)


class Overlay(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="dev.dostov.miami-bus-overlay")
        self.started = time.monotonic()
        self.misses = 0

    def do_activate(self):
        css = Gtk.CssProvider()
        css.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css, 800)

        self.stop = stop_info()
        win = Gtk.ApplicationWindow(application=self, default_width=380, default_height=320)
        win.add_css_class("bus-overlay")
        LayerShell.init_for_window(win)
        LayerShell.set_layer(win, LayerShell.Layer.TOP)
        for edge in (LayerShell.Edge.BOTTOM, LayerShell.Edge.RIGHT):
            LayerShell.set_anchor(win, edge, True)
            LayerShell.set_margin(win, edge, 16)

        header = Gtk.Box()
        title = Gtk.Label(xalign=0, hexpand=True, use_markup=True)
        title.set_markup(
            f"🚌 {ROUTE} {DIR} · {GLib.markup_escape_text(self.stop['StopName'])}"
            "  <small><span alpha='45%'>© Esri · OSM</span></small>"
        )
        title.add_css_class("bus-header")
        close = Gtk.Button(icon_name="window-close-symbolic", has_frame=False)
        close.connect("clicked", lambda *_: win.close())
        header.append(title)
        header.append(close)

        self.eta = Gtk.Label(label="fetching…", xalign=0)
        self.eta.add_css_class("bus-eta")

        self.map = Shumate.SimpleMap()
        # Esri's dark canvas has no labels, unlike OSM Mapnik; attribution lives in the title. Path order is z/y/x.
        self.map.set_map_source(Shumate.RasterRenderer.new_full_from_url(
            "esri-dark", "Esri World Dark Gray Base", "Esri, HERE, Garmin, © OpenStreetMap contributors",
            "https://www.esri.com/en-us/legal/terms/full-master-agreement", 0, 16, 256, Shumate.MapProjection.MERCATOR,
            "https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}",
        ))
        self.map.set_vexpand(True)
        self.map.set_show_zoom_buttons(False)
        self.map.get_scale().set_visible(False)
        self.map.get_license().set_visible(False)
        viewport = self.map.get_viewport()
        viewport.set_zoom_level(13)
        viewport.set_location(self.stop["Lat"], self.stop["Long"])
        color = Gdk.RGBA()
        color.parse("#fe640b")
        shapes = api(f"shape?routeId={ROUTE}&mapMode=bus")
        # Shapes carry no direction; keep the ones same-direction buses are on, all of them if none is out.
        active = {v["ShapeID"] for v in api(VEHICLES) if f"TextStr={DIR[0]}B" in v["RouteImage"]}
        for shape in [s for s in shapes if s["Id"] in active] or shapes:
            path = Shumate.PathLayer.new(viewport)
            path.set_stroke_width(4)
            path.set_stroke_color(color)
            for p in shape["Shapes"]:
                path.add_node(Shumate.Coordinate.new_full(p["Latitude"], p["Longitude"]))
            self.map.add_overlay_layer(path)

        self.markers = Shumate.MarkerLayer.new(viewport)
        self.map.add_overlay_layer(self.markers)
        self.markers.add_marker(self._marker("marker-stop", "", f"Stop {STOP}: {self.stop['StopName']}", self.stop["Lat"], self.stop["Long"]))

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.append(header)
        box.append(self.eta)
        box.append(self.map)
        win.set_child(box)
        win.present()

        threading.Thread(target=self._poll, daemon=True).start()

    def _marker(self, css, text, tooltip, lat, lon):
        m = Shumate.Marker()
        label = Gtk.Label(label=text, tooltip_text=tooltip)
        label.add_css_class(css)
        m.set_child(label)
        m.set_location(lat, lon)
        return m

    def _poll(self):
        while True:
            try:
                arrivals = api(f"tracker?routeID={ROUTE}&directionId={DIR}&stopID={STOP}&track=NO")
                vehicles = {v["ID"]: v for v in api(VEHICLES)}
            except Exception as e:  # ponytail: transient API errors just skip a tick
                GLib.idle_add(self.eta.set_text, f"API error: {e}")
                arrivals, vehicles = [], {}
            GLib.idle_add(self._render, arrivals, vehicles)
            time.sleep(POLL)

    def _render(self, arrivals, vehicles):
        imminent = any(a["TimeEst"] <= NOTIFY_MIN * 60 for a in arrivals)
        self.misses = 0 if imminent else self.misses + 1
        if self.misses >= MAX_MISSES or time.monotonic() - self.started > MAX_AGE:
            self.quit()
            return False

        lines = [
            f"{a['Estimate']:>3} min  {a['ArrivalTime'][11:16]}  bus {a['VehicleName']}  ({a['EstType']})"
            for a in arrivals[:3]
        ] or ["no buses predicted"]
        self.eta.set_text("\n".join(lines))

        for m in list(self.markers.get_markers())[1:]:
            self.markers.remove_marker(m)
        eta = {str(a["VehicleID"]): a for a in arrivals}
        # The vehicles feed is not a superset of the predictions, so also draw every same-direction bus.
        for vid, v in vehicles.items():
            a = eta.get(vid)
            if a:
                self.markers.add_marker(self._marker("marker-bus", f"🚌 {a['Estimate']}m", f"Bus {a['VehicleName']} → {a['Headsign']}", v["Latitude"], v["Longitude"]))
            elif f"TextStr={DIR[0]}B" in v["RouteImage"]:
                self.markers.add_marker(self._marker("marker-bus-other", "🚌", f"Bus {vid}", v["Latitude"], v["Longitude"]))
        return False


if __name__ == "__main__":
    Overlay().run(None)
