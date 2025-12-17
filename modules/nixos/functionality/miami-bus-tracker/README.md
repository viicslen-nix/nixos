# Miami Bus Tracker Module

NixOS module for tracking the nearest westbound 836 bus to the SW 1st St and 1st Ave stop in Miami, FL.

## Features

- Automatic periodic checking of bus arrival times using Miami-Dade Transit API
- Desktop notifications when a bus is approaching (optional)
- Helper command to find the correct stop ID
- Configurable check interval
- Manual bus checking via command line

## Configuration

Add to your NixOS configuration:

```nix
{
  services.miami-bus-tracker = {
    enable = true;
    
    # Optional: Customize the stop ID (use miami-find-stop to discover)
    stopId = "3096";  # Replace with actual stop ID
    
    # Optional: Check every 5 minutes (default)
    interval = "5min";
    
    # Optional: Enable desktop notifications
    notification = true;
    
    # Optional: Notify when bus is within 5 minutes (default)
    notifyMinutes = 5;
  };
}
```

## Finding the Correct Stop ID

Before using the tracker, you need to find the correct stop ID for SW 1st St and 1st Ave:

```bash
# Search for stops on route 836 westbound
miami-find-stop "SW 1"

# Or search for a different pattern
miami-find-stop "1st"
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
miami-bus-tracker
```

This will display:
- Stop information
- Current time
- Next 3 buses arriving (if available)
- Estimated arrival times
- Bus IDs and destinations

### Service Management

```bash
# Check timer status
systemctl status miami-bus-tracker.timer

# Check service status
systemctl status miami-bus-tracker.service

# Manually trigger a check
systemctl start miami-bus-tracker.service

# Restart the timer
systemctl restart miami-bus-tracker.timer
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
Stop: SW 1st St and 1st Ave
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

When notifications are enabled and a bus is approaching within the configured time window, you'll receive a desktop notification:

```
🚌 Bus 836 Westbound Approaching
Bus 1234 arriving in 5 minute(s) at SW 1st St & 1st Ave
```

## Troubleshooting

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
