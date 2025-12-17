{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.miami-bus-tracker;
  
  # Script to fetch and display bus tracker info
  busTrackerScript = pkgs.writeShellScriptBin "miami-bus-tracker" ''
    set -euo pipefail
    
    # Route 836 (we need to find the actual RouteID)
    ROUTE_ID="836"
    # Direction: Westbound
    DIR="Westbound"
    # Stop at SW 1st St and 1st Ave (we need to find the actual StopID)
    # This is a placeholder - you'll need to look up the actual stop ID
    STOP_ID="${cfg.stopId}"
    NOTIFY="${toString cfg.notification}"
    NOTIFY_MINUTES="${toString cfg.notifyMinutes}"
    
    echo "=== Miami-Dade Transit Bus Tracker ==="
    echo "Route: $ROUTE_ID $DIR"
    echo "Stop: SW 1st St and 1st Ave"
    echo "Time: $(date)"
    echo ""
    
    # Fetch bus tracker data
    URL="http://www.miamidade.gov/transit/WebServices/BusTracker/?StopID=$STOP_ID&RouteID=$ROUTE_ID&Dir=$DIR"
    
    RESPONSE=$(${pkgs.curl}/bin/curl -s "$URL")
    
    if [ -z "$RESPONSE" ]; then
      echo "Error: No response from API"
      exit 1
    fi
    
    # Extract first arrival time estimate
    TIME1_EST=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Est" 2>/dev/null || echo "")
    
    # Parse XML and display results
    echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t \
      -m "//RecordSet/Record" \
      -v "concat('Stop: ', StopName)" -n \
      -v "concat('Route: ', RouteID, ' ', Direction)" -n \
      -n \
      -m "." \
      -o "Next buses:" -n \
      -m "." \
      -i "Time1" \
      -o "  1. " \
      -v "concat('Arrival: ', Time1_Arrival, ' (', Time1_Est, ')')" -n \
      -v "concat('     Bus: ', Time1_Bus_Name, ' (', Time1_Bus_ID, ')')" -n \
      -v "concat('     Destination: ', Time1_Headsign)" -n \
      -b \
      -m "." \
      -i "Time2" \
      -o "  2. " \
      -v "concat('Arrival: ', Time2_Arrival, ' (', Time2_Est, ')')" -n \
      -v "concat('     Bus: ', Time2_Bus_Name, ' (', Time2_Bus_ID, ')')" -n \
      -v "concat('     Destination: ', Time2_Headsign)" -n \
      -b \
      -m "." \
      -i "Time3" \
      -o "  3. " \
      -v "concat('Arrival: ', Time3_Arrival, ' (', Time3_Est, ')')" -n \
      -v "concat('     Bus: ', Time3_Bus_Name, ' (', Time3_Bus_ID, ')')" -n \
      -v "concat('     Destination: ', Time3_Headsign)" -n \
      -b 2>/dev/null || echo "No bus data available or parsing error"
    
    # Send notification if enabled and bus is approaching
    if [ "$NOTIFY" = "true" ] && [ -n "$TIME1_EST" ]; then
      # Extract minutes from estimate (assuming format like "5 minute(s)")
      MINUTES=$(echo "$TIME1_EST" | ${pkgs.gnugrep}/bin/grep -oP '^\d+' || echo "999")
      
      if [ "$MINUTES" -le "$NOTIFY_MINUTES" ]; then
        BUS_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Bus_Name" 2>/dev/null || echo "Unknown")
        ${pkgs.libnotify}/bin/notify-send -u normal -t 10000 \
          "🚌 Bus 836 Westbound Approaching" \
          "Bus $BUS_NAME arriving in $TIME1_EST at SW 1st St & 1st Ave"
      fi
    fi
    
    echo ""
    echo "=== End of Report ==="
  '';
  
  # Helper script to find stop ID
  findStopScript = pkgs.writeShellScriptBin "miami-find-stop" ''
    set -euo pipefail
    
    SEARCH_TERM="''${1:-SW 1}"
    
    echo "Searching for stops matching: $SEARCH_TERM"
    echo ""
    
    # Get all stops for route 836
    URL="http://www.miamidade.gov/transit/WebServices/BusRouteStops/?RouteID=836&Dir=Westbound"
    
    ${pkgs.curl}/bin/curl -s "$URL" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t \
      -m "//RecordSet/Record" \
      -v "concat('StopID: ', StopID, ' | ', StopName, ' | Seq: ', Sequence)" -n \
      2>/dev/null | ${pkgs.gnugrep}/bin/grep -i "$SEARCH_TERM" || echo "No matching stops found"
  '';

in {
  options.services.miami-bus-tracker = {
    enable = mkEnableOption "Miami-Dade Transit Bus Tracker for Route 836";
    
    stopId = mkOption {
      type = types.str;
      default = "3096";  # Placeholder - replace with actual stop ID
      description = ''
        The Stop ID for SW 1st St and 1st Ave.
        Use miami-find-stop command to discover the correct stop ID.
      '';
    };
    
    interval = mkOption {
      type = types.str;
      default = "5min";
      description = ''
        How often to check for bus arrivals.
        Uses systemd timer interval format (e.g., "5min", "10min", "hourly").
      '';
    };
    
    notification = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to send desktop notifications when a bus is approaching.
      '';
    };
    
    notifyMinutes = mkOption {
      type = types.int;
      default = 5;
      description = ''
        Send notification when bus is within this many minutes.
      '';
    };
  };
  
  config = mkIf cfg.enable {
    # Add helper scripts to system packages
    environment.systemPackages = [
      busTrackerScript
      findStopScript
    ];
    
    # Systemd service
    systemd.services.miami-bus-tracker = {
      description = "Check for nearest westbound 836 bus";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${busTrackerScript}/bin/miami-bus-tracker";
        User = "nobody";
        Group = "nogroup";
      };
      path = with pkgs; [ curl xmlstarlet gnugrep ];
    };
    
    # Systemd timer
    systemd.timers.miami-bus-tracker = {
      description = "Timer for Miami Bus Tracker";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.interval;
        Unit = "miami-bus-tracker.service";
      };
    };
  };
}
