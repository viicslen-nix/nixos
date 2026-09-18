# Miami Bus Tracker Module

NixOS module that watches one Miami-Dade Transit bus stop, notifies you when the
next bus is close, and pops up a small corner map with the live bus position.

## Features

- Periodic check of arrival predictions for one route/direction/stop
- **Time-based checking** — only check during a window (e.g. after 5 PM)
- Desktop notification when a bus is within `notifyMinutes`
- **Corner map overlay** — a layer-shell window (bottom-right) with the next
  arrivals and a dark basemap with the route, the stop and the predicted buses,
  refreshed every 10 s; closes itself when no bus is imminent
- `miami-find-stop` to discover the stop ID, `miami-bus-tracker` for a manual check

## Configuration

```nix
{
  services.miami-bus-tracker = {
    enable = true;

    routeId = "836";         # default "836"
    direction = "Westbound"; # direction name as the API spells it
    stopId = "3096";         # use miami-find-stop

    interval = "5min";       # systemd timer interval

    activeTimeStart = "17:00"; # empty = always; end < start crosses midnight
    activeTimeEnd = "23:00";

    notification = true;     # desktop notification
    notifyMinutes = 5;       # within this many minutes
    overlay = true;          # also show the map overlay (default true, needs notification)
  };
}
```

## Finding the stop ID

```bash
miami-find-stop "SW 1"     # searches the configured route/direction
miami-find-stop            # lists every stop
```

## Usage

```bash
miami-bus-tracker          # next buses for the configured stop
miami-bus-tracker -v       # also dump the raw JSON
miami-bus-overlay          # preview the overlay by hand
```

```
=== Miami-Dade Transit Bus Tracker ===
Route: 836 Westbound   Stop: 1340   Thu Sep 17 04:49:43 PM EDT 2026

1. 8 min (16:58)  bus 18158  → 836 - Dolphin Park & Ride  [RealTime]
2. 18 min (17:08)  bus 18136  → 836 - Dolphin Park & Ride  [RealTime]
3. 49 min (17:38)  bus 20210  → 836 - Dolphin Park & Ride  [RealTime]
```

Manual runs ignore the active-time window and never notify.

### Services

- `miami-bus-notify.timer` / `.service` (system) — the periodic check; runs
  `ConditionTime` and notifies every logged-in user.
- `miami-bus-overlay.service` (user) — started by the check inside each user's
  session; exits on its own once the bus is gone, or via its × button.

```bash
systemctl status miami-bus-notify.timer
systemctl start miami-bus-notify.service        # force a check now
journalctl -u miami-bus-notify.service -n 20
systemctl --user status miami-bus-overlay.service
```

## API

The JSON API behind the county's own tracker page:

- **Base URL**: `https://www.miamidade.gov/apps/dtpw/transitapps/api/bus`
- **Auth**: `x-api-key` header; the default `apiKey` is the public key the
  county page ships, override it if they rotate it
- **Endpoints**: `tracker` (predictions for a stop), `routestops` (stops with
  coordinates), `vehicles` (live positions)
- `directionId` is the direction *name* (`Westbound`), not a number

See `CONTEXT.md` for how this was found and the traps around it.

## Troubleshooting

- **Nothing happens during the day** — `activeTimeStart` gates the timer;
  `miami-bus-tracker` always runs.
- **No data** — check the stop with `miami-find-stop` and the raw response with
  `miami-bus-tracker -v`.
- **No notification / overlay** — `notification = true`, a Wayland session
  (`WAYLAND_DISPLAY` must be set in the user manager), D-Bus in the session.
- **Overlay opens as a normal window** — the layer-shell preload is missing;
  see `CONTEXT.md`.
