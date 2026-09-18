# Miami bus tracker

## The API moved

The original XML feed at `miamidade.gov/transit/WebServices/BusTracker/` was
archived and now 404s; the `/transit/mobile/xml/` variant redirects to the app
landing page, and the Swiftly transitime feed the community docs list loops on
a 301. What still works is what the county's own tracker page calls: a JSON
API under `https://www.miamidade.gov/apps/dtpw/transitapps/api/bus`, found by
reading `js/bus_tracker_component.js` and `js/transit_map_component.js` from
that page.

- `routedirections?routeID=` — direction names.
- `routestops?routeID=&directionId=` — stops with `Lat`/`Long`.
- `tracker?routeID=&directionId=&stopID=&track=NO` — predictions:
  `Estimate` (minutes, string), `TimeEst` (seconds), `ArrivalTime`,
  `VehicleID`, `VehicleName`, `Headsign`, `EstType`.
- `vehicles?routeId=&mapMode=bus&track=NO&curLatitude=0&curLongitude=0` —
  every bus on the route in both directions, `ID`/`Latitude`/`Longitude`.

Two traps. `directionId` is the direction *name* (`Westbound`); the numeric
`DirectionID` that `routedirections` also returns yields an empty array, not an
error. And the key is mandatory (500 without it) but is the public one embedded
as `apikey=` in the county page's `<bus-tracker>` element; it is an option so it
can be swapped when they rotate it. The county WAF also 403s Python-urllib's
default User-Agent while accepting curl's, hence the browser UA in `overlay.py`.

Buses on the map are matched by `tracker.VehicleID == vehicles.ID` to get an
ETA label. That is not enough on its own: the vehicles feed is not a superset
of the predictions (a bus predicted 14 min out as `RealTime` was missing from
it while one 76 min out was listed), and `curLatitude`/`curLongitude`/`track`
change nothing. So every same-direction bus is drawn too, dimmer, with the
direction read from `RouteImage`'s `TextStr=WB`-style parameter.

## Why the overlay is a user unit started by a root timer

The notify timer is a system service (it notifies every logged-in user via
`sudo -u`). The active window is checked by the script, not the unit: the
original module set `ConditionTime=`, which systemd does not have — the journal
says `Unknown key 'ConditionTime' in section [Unit], ignoring` — so the window
never existed and notifications fired all day once the API worked again. A Wayland window has to live in the
session, so the same loop runs `systemctl --user start miami-bus-overlay` with
the user's `XDG_RUNTIME_DIR`/`DBUS_SESSION_BUS_ADDRESS`, and the unit inherits
`WAYLAND_DISPLAY` from the user manager. Starting an already-running unit is a
no-op, so the 5-minute timer never stacks overlays; the overlay exits itself
after three polls with no bus inside `notifyMinutes`, or after 30 minutes.

## Basemap

OSM Mapnik (libshumate's default) drowns a 400px map in POI labels. CARTO's
dark basemap was the first replacement, but it now serves an "API KEY
REQUIRED" watermark without a key. Esri's World Dark Gray Base has no labels,
needs no key, and is what the county page itself renders on (ArcGIS). Its tile
path is `{z}/{y}/{x}`, not `{z}/{x}/{y}`, and libshumate templates use those
brace placeholders — `#Z#`-style ones from libchamplain silently 404 every
tile, which shows up as a transparent map, not an error. The license widget is
hidden and a short attribution sits in the title instead, because
`Shumate.License` wraps to three lines at this width.

The overlay is GTK4 + libshumate (native OSM tiles, no browser engine) +
gtk4-layer-shell through PyGObject. The layer-shell library must be loaded
before `libwayland-client`, which gi cannot guarantee, so the wrapper
`LD_PRELOAD`s it; without that the window is an ordinary toplevel. Verified on
Hyprland (`hyprctl layers` shows namespace `gtk4-layer-shell` at the top level).
