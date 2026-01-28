# Miami Bus Tracker Module

NixOS module for tracking the nearest westbound 836 bus to the SW 1st St and 1st Ave stop in Miami, FL.

## Features

- Automatic periodic checking of bus arrival times using Miami-Dade Transit API
- **Time-based checking** - Only check during specific hours (e.g., only after 5 PM)
- Desktop notifications when a bus is approaching (optional)
- Helper command to find the correct stop ID
- Configurable check interval
- Manual bus checking via command line (bypasses time restrictions)

## Configuration

Add to your NixOS configuration:

```nix
{
  services.miami-bus-tracker = {
    enable = true;

    # Route configuration
    routeId = "836";        # Bus route number (default: "836")
    direction = "Westbound"; # Direction (default: "Westbound")
    stopId = "3096";        # Stop ID (use miami-find-stop to discover)

    # Optional: Check every 5 minutes (default)
    interval = "5min";

    # Optional: Only check after 5 PM (17:00) until 11 PM (23:00)
    activeTimeStart = "17:00";
    activeTimeEnd = "23:00";

    # Optional: Enable desktop notifications
    notification = true;

    # Optional: Notify when bus is within 5 minutes (default)
    notifyMinutes = 5;
  };
}
```

### Route Configuration Examples

```nix
# Track route 95 Northbound
services.miami-bus-tracker = {
  enable = true;
  routeId = "95";
  direction = "Northbound";
  stopId = "1234";  # Your stop ID
};

# Track route 11 Southbound
services.miami-bus-tracker = {
  enable = true;
  routeId = "11";
  direction = "Southbound";
  stopId = "5678";  # Your stop ID
};
```

### Time-Based Checking Examples

```nix
# Only check after 5 PM until midnight
activeTimeStart = "17:00";
activeTimeEnd = "23:59";

# Check from 6 AM to 9 AM (morning commute)
activeTimeStart = "06:00";
activeTimeEnd = "09:00";

# Check from 10 PM to 2 AM (crosses midnight)
activeTimeStart = "22:00";
activeTimeEnd = "02:00";

# Check at all times (leave activeTimeStart empty)
activeTimeStart = "";
```

## Finding the Correct Stop ID

Before using the tracker, you need to find the correct stop ID. The `miami-find-stop` command will search stops for your configured route and direction:

```bash
# Search for stops on your configured route (uses your config settings)
miami-find-stop "SW 1"

# Search for a different pattern
miami-find-stop "1st"

# Search for stops on a specific street
miami-find-stop "Flagler"
```

Once you find the correct stop ID, update your configuration.

## Usage

### Automatic Tracking

Once enabled, the service will automatically check for buses at the configured interval. You can view the logs:

```bash
# View recent bus tracker logs
journalctl -u miami-bus-tracker.service -n 50

# Follow logs in real-time
journalctl -u miami-bus-tracker.service -f
```

### Manual Check

You can manually check for buses at any time:

```bash
# Check buses immediately (always works, even outside active time window)
miami-bus-tracker
```

This will display:

- Stop information
- Current time
- Next 3 buses arriving (if available)
- Estimated arrival times
- Bus IDs and destinations

**Note:** Manual runs with `miami-bus-tracker` do not send notifications and are not subject to time restrictions. The `activeTimeStart` and `activeTimeEnd` settings only affect the automatic systemd timer-based checks and notifications.

### Service Management

```bash
# Check tracker timer status
systemctl status miami-bus-tracker.timer

# Check tracker service status
systemctl status miami-bus-tracker.service

# Check notification timer status (if enabled)
systemctl status miami-bus-notify.timer

# Check notification service status (if enabled)
systemctl status miami-bus-notify.service

# Manually trigger a check (no notification)
systemctl start miami-bus-tracker.service

# Manually trigger a notification check
systemctl start miami-bus-notify.service

# Restart the timers
systemctl restart miami-bus-tracker.timer
systemctl restart miami-bus-notify.timer
```

## API Information

This module uses the Miami-Dade Transit BusTracker XML API:

- **Endpoint**: `http://www.miamidade.gov/transit/WebServices/BusTracker/`
- **Required Parameters**:
  - `StopID`: The bus stop identifier
  - `RouteID`: Route number (836)
  - `Dir`: Direction (Westbound)

## Example Output

```
=== Miami-Dade Transit Bus Tracker ===
Route: 836 Westbound
Stop ID: 3096
Time: Tue Dec 17 09:30:00 EST 2025

Stop: SW 1 ST & SW 1 AVE
Route: 836 Westbound

Next buses:
  1. Arrival: 09:35:00 (5 minute(s))
     Bus: 1234 (BUS-1234)
     Destination: Dolphin Mall
  2. Arrival: 09:50:00 (20 minute(s))
     Bus: 5678 (BUS-5678)
     Destination: Dolphin Mall
  3. Arrival: 10:05:00 (35 minute(s))
     Bus: 9012 (BUS-9012)
     Destination: Dolphin Mall

=== End of Report ===
```

## Notifications

When notifications are enabled, a separate systemd service (`miami-bus-notify`) runs on the same schedule as the tracker. When a bus is approaching within the configured time window, you'll receive a desktop notification:

```
🚌 Bus 836 Westbound Approaching
Bus 1234 arriving in 5 minute(s) at SW 1 ST & SW 1 AVE
```

The notification will use your configured route, direction, and the actual stop name from the API.

**Important Notes:**

- Notifications are only sent by the systemd timer service, not by manual `miami-bus-tracker` runs
- Notifications respect the `activeTimeStart` and `activeTimeEnd` settings
- The notification service runs independently and will attempt to notify all logged-in users

## Troubleshooting

### Service runs but doesn't check buses

If you've configured `activeTimeStart`, the systemd service will not run outside the active time window due to `ConditionTime`. Check the timer status:

```bash
systemctl status miami-bus-tracker.timer
journalctl -u miami-bus-tracker.service -n 20
```

The service condition will prevent execution outside the configured hours. To check buses regardless of time, run manually:

```bash
miami-bus-tracker
```

This bypasses the systemd time conditions and always runs.

### No data returned

1. Verify the stop ID is correct using `miami-find-stop`
2. Check if route 836 runs westbound through this stop
3. Verify the API is accessible: `curl "http://www.miamidade.gov/transit/WebServices/BusRoutes/?RouteID=836"`

### Service not running

```bash
# Check timer status
systemctl status miami-bus-tracker.timer

# Enable and start the timer
systemctl enable --now miami-bus-tracker.timer
```

### Notifications not working

1. Ensure `notification = true` in your configuration
2. Verify you're running a desktop environment with notification support
3. Check that D-Bus is available for your user session

## Dependencies

The module automatically includes:

- `curl` - For API requests
- `xmlstarlet` - For XML parsing
- `libnotify` - For desktop notifications (when enabled)
- `gnugrep` - For text processing

## License

Part of the nixos configuration repository.
