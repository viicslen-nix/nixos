{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.miami-bus-tracker;

  # Script to fetch and display bus tracker info
  busTrackerScript = pkgs.writeShellScriptBin "miami-bus-tracker" ''
    set -euo pipefail

    ROUTE_ID="${cfg.routeId}"
    DIR="${cfg.direction}"
    STOP_ID="${cfg.stopId}"
    VERBOSE=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case $1 in
        -v|--verbose)
          VERBOSE=true
          shift
          ;;
        *)
          echo "Unknown option: $1"
          echo "Usage: miami-bus-tracker [-v|--verbose]"
          exit 1
          ;;
      esac
    done

    # Function to convert Time_Est (seconds) to readable format
    format_time() {
      local seconds=$1
      if [ -z "$seconds" ] || [ "$seconds" -eq 0 ]; then
        echo "Now"
        return
      fi

      local minutes=$((seconds / 60))
      local hours=$((minutes / 60))
      local remaining_minutes=$((minutes % 60))

      if [ $hours -gt 0 ]; then
        if [ $remaining_minutes -gt 0 ]; then
          echo "$hours hr $remaining_minutes min"
        else
          echo "$hours hr"
        fi
      else
        echo "$minutes min"
      fi
    }

    echo "=== Miami-Dade Transit Bus Tracker ==="
    echo "Route: $ROUTE_ID $DIR"
    echo "Stop ID: $STOP_ID"
    echo "Time: $(date)"
    echo ""

    # Fetch bus tracker data
    URL="http://www.miamidade.gov/transit/WebServices/BusTracker/?StopID=$STOP_ID&RouteID=$ROUTE_ID&Dir=$DIR"

    RESPONSE=$(${pkgs.curl}/bin/curl -s "$URL")

    if [ -z "$RESPONSE" ]; then
      echo "Error: No response from API"
      exit 1
    fi

    # Output raw response if verbose mode is enabled
    if [ "$VERBOSE" = true ]; then
      echo "=== Raw HTTP Response ==="
      echo "$RESPONSE"
      echo ""
    fi

    # Fix malformed XML: replace unescaped & with &amp;
    # First, temporarily replace all &amp; with a placeholder to protect them
    # Then replace all remaining & with &amp;
    # Finally, restore the placeholder back to &amp;
    RESPONSE=$(echo "$RESPONSE" | ${pkgs.gnused}/bin/sed -e 's/&amp;/__AMPERSAND__/g' -e 's/&/\&amp;/g' -e 's/__AMPERSAND__/\&amp;/g')

    if [ "$VERBOSE" = true ]; then
      echo "=== Sanitized XML ==="
      echo "$RESPONSE"
      echo ""
      echo "=== Parsed Output ==="
    fi

    # Parse and display results with formatted times
    if [ "$VERBOSE" = true ]; then
      STOP_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/StopName" 2>&1 || echo "")
      ROUTE_INFO=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "concat(//RecordSet/Record/RouteID, ' ', //RecordSet/Record/Direction)" 2>&1 || echo "")
    else
      STOP_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/StopName" 2>/dev/null || echo "")
      ROUTE_INFO=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "concat(//RecordSet/Record/RouteID, ' ', //RecordSet/Record/Direction)" 2>/dev/null || echo "")
    fi

    if [ -n "$STOP_NAME" ]; then
      echo "Stop: $STOP_NAME"
      echo "Route: $ROUTE_INFO"
      echo ""
      echo "Next buses:"

      # Process Time1
      if [ "$VERBOSE" = true ]; then
        TIME1_EST=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Est" 2>&1 || echo "")
      else
        TIME1_EST=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Est" 2>/dev/null || echo "")
      fi
      if [ -n "$TIME1_EST" ]; then
        if [ "$VERBOSE" = true ]; then
          TIME1_ARRIVAL=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Arrival" 2>&1 || echo "")
          TIME1_BUS_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Bus_Name" 2>&1 || echo "")
          TIME1_BUS_ID=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Bus_ID" 2>&1 || echo "")
          TIME1_HEADSIGN=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Headsign" 2>&1 || echo "")
        else
          TIME1_ARRIVAL=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Arrival" 2>/dev/null || echo "")
          TIME1_BUS_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Bus_Name" 2>/dev/null || echo "")
          TIME1_BUS_ID=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Bus_ID" 2>/dev/null || echo "")
          TIME1_HEADSIGN=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Headsign" 2>/dev/null || echo "")
        fi
        TIME1_FORMATTED=$(format_time "$TIME1_EST")

        echo "  1. Arrival: $TIME1_ARRIVAL ($TIME1_FORMATTED)"
        echo "     Bus: $TIME1_BUS_NAME ($TIME1_BUS_ID)"
        echo "     Destination: $TIME1_HEADSIGN"
      fi

      # Process Time2
      if [ "$VERBOSE" = true ]; then
        TIME2_EST=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Est" 2>&1 || echo "")
      else
        TIME2_EST=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Est" 2>/dev/null || echo "")
      fi
      if [ -n "$TIME2_EST" ]; then
        if [ "$VERBOSE" = true ]; then
          TIME2_ARRIVAL=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Arrival" 2>&1 || echo "")
          TIME2_BUS_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Bus_Name" 2>&1 || echo "")
          TIME2_BUS_ID=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Bus_ID" 2>&1 || echo "")
          TIME2_HEADSIGN=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Headsign" 2>&1 || echo "")
        else
          TIME2_ARRIVAL=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Arrival" 2>/dev/null || echo "")
          TIME2_BUS_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Bus_Name" 2>/dev/null || echo "")
          TIME2_BUS_ID=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Bus_ID" 2>/dev/null || echo "")
          TIME2_HEADSIGN=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time2_Headsign" 2>/dev/null || echo "")
        fi
        TIME2_FORMATTED=$(format_time "$TIME2_EST")

        echo "  2. Arrival: $TIME2_ARRIVAL ($TIME2_FORMATTED)"
        echo "     Bus: $TIME2_BUS_NAME ($TIME2_BUS_ID)"
        echo "     Destination: $TIME2_HEADSIGN"
      fi

      # Process Time3
      if [ "$VERBOSE" = true ]; then
        TIME3_EST=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Est" 2>&1 || echo "")
      else
        TIME3_EST=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Est" 2>/dev/null || echo "")
      fi
      if [ -n "$TIME3_EST" ]; then
        if [ "$VERBOSE" = true ]; then
          TIME3_ARRIVAL=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Arrival" 2>&1 || echo "")
          TIME3_BUS_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Bus_Name" 2>&1 || echo "")
          TIME3_BUS_ID=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Bus_ID" 2>&1 || echo "")
          TIME3_HEADSIGN=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Headsign" 2>&1 || echo "")
        else
          TIME3_ARRIVAL=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Arrival" 2>/dev/null || echo "")
          TIME3_BUS_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Bus_Name" 2>/dev/null || echo "")
          TIME3_BUS_ID=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Bus_ID" 2>/dev/null || echo "")
          TIME3_HEADSIGN=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time3_Headsign" 2>/dev/null || echo "")
        fi
        TIME3_FORMATTED=$(format_time "$TIME3_EST")

        echo "  3. Arrival: $TIME3_ARRIVAL ($TIME3_FORMATTED)"
        echo "     Bus: $TIME3_BUS_NAME ($TIME3_BUS_ID)"
        echo "     Destination: $TIME3_HEADSIGN"
      fi
    else
      echo "No bus data available or parsing error"
    fi

    echo ""
    echo "=== End of Report ==="
  '';

  # Script to check and send notifications
  notificationScript = pkgs.writeShellScriptBin "miami-bus-notify" ''
    set -euo pipefail

    ROUTE_ID="${cfg.routeId}"
    DIR="${cfg.direction}"
    STOP_ID="${cfg.stopId}"
    NOTIFY_MINUTES="${toString cfg.notifyMinutes}"

    # Function to convert Time_Est (seconds) to readable format
    format_time() {
      local seconds=$1
      if [ -z "$seconds" ] || [ "$seconds" -eq 0 ]; then
        echo "Now"
        return
      fi

      local minutes=$((seconds / 60))
      local hours=$((minutes / 60))
      local remaining_minutes=$((minutes % 60))

      if [ $hours -gt 0 ]; then
        if [ $remaining_minutes -gt 0 ]; then
          echo "$hours hr $remaining_minutes min"
        else
          echo "$hours hr"
        fi
      else
        echo "$minutes min"
      fi
    }

    # Fetch bus tracker data
    URL="http://www.miamidade.gov/transit/WebServices/BusTracker/?StopID=$STOP_ID&RouteID=$ROUTE_ID&Dir=$DIR"
    RESPONSE=$(${pkgs.curl}/bin/curl -s "$URL")

    if [ -z "$RESPONSE" ]; then
      exit 1
    fi

    # Fix malformed XML: replace unescaped & with &amp;
    # First, temporarily replace all &amp; with a placeholder to protect them
    # Then replace all remaining & with &amp;
    # Finally, restore the placeholder back to &amp;
    RESPONSE=$(echo "$RESPONSE" | ${pkgs.gnused}/bin/sed -e 's/&amp;/__AMPERSAND__/g' -e 's/&/\&amp;/g' -e 's/__AMPERSAND__/\&amp;/g')

    # Extract first arrival time estimate (in seconds)
    TIME1_EST=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Est" 2>/dev/null || echo "")

    if [ -n "$TIME1_EST" ]; then
      # Convert seconds to minutes
      MINUTES=$((TIME1_EST / 60))

      if [ "$MINUTES" -le "$NOTIFY_MINUTES" ]; then
        BUS_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/Time1_Bus_Name" 2>/dev/null || echo "Unknown")
        STOP_NAME=$(echo "$RESPONSE" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -v "//RecordSet/Record/StopName" 2>/dev/null || echo "Stop $STOP_ID")
        TIME_FORMATTED=$(format_time "$TIME1_EST")

        # Send notification to all active user sessions
        for user_id in $(${pkgs.systemd}/bin/loginctl list-users --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
          user_name=$(${pkgs.systemd}/bin/loginctl show-user "$user_id" -p Name --value)
          user_runtime_dir="/run/user/$user_id"

          if [ -d "$user_runtime_dir" ]; then
            sudo -u "$user_name" DBUS_SESSION_BUS_ADDRESS="unix:path=$user_runtime_dir/bus" \
              ${pkgs.libnotify}/bin/notify-send -u normal -t 10000 \
                "🚌 Bus $ROUTE_ID $DIR Approaching" \
                "Bus $BUS_NAME arriving in $TIME_FORMATTED at $STOP_NAME" || true
          fi
        done
      fi
    fi
  '';

  # Helper script to find stop ID
  findStopScript = pkgs.writeShellScriptBin "miami-find-stop" ''
    set -euo pipefail

    ROUTE_ID="${cfg.routeId}"
    DIR="${cfg.direction}"
    SEARCH_TERM="''${1:-SW 1}"

    echo "Searching for stops on route $ROUTE_ID $DIR matching: $SEARCH_TERM"
    echo ""

    URL="http://www.miamidade.gov/transit/WebServices/BusRouteStops/?RouteID=$ROUTE_ID&Dir=$DIR"

    ${pkgs.curl}/bin/curl -s "$URL" | ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t \
      -m "//RecordSet/Record" \
      -v "concat('StopID: ', StopID, ' | ', StopName, ' | Seq: ', Sequence)" -n \
      2>/dev/null | ${pkgs.gnugrep}/bin/grep -i "$SEARCH_TERM" || echo "No matching stops found"
  '';

in {
  options.services.miami-bus-tracker = {
    enable = mkEnableOption "Miami-Dade Transit Bus Tracker";

    routeId = mkOption {
      type = types.str;
      default = "836";
      example = "836";
      description = ''
        The route ID to track.
      '';
    };

    direction = mkOption {
      type = types.str;
      default = "Westbound";
      example = "Eastbound";
      description = ''
        The direction of the route to track (e.g., "Northbound", "Southbound", "Eastbound", "Westbound").
      '';
    };

    stopId = mkOption {
      type = types.str;
      default = "3096";
      description = ''
        The Stop ID for the bus stop to track.
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

    activeTimeStart = mkOption {
      type = types.str;
      default = "";
      example = "17:00";
      description = ''
        Start time for active checking in 24-hour format (HH:MM).
        Leave empty to check at all times.
        Example: "17:00" to start checking after 5 PM.
      '';
    };

    activeTimeEnd = mkOption {
      type = types.str;
      default = "23:59";
      example = "23:00";
      description = ''
        End time for active checking in 24-hour format (HH:MM).
        Only used if activeTimeStart is set.
        Can be before activeTimeStart to represent a range crossing midnight.
        Example: "23:00" to stop checking after 11 PM.
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
      description = "Check for nearest ${cfg.routeId} ${cfg.direction} bus";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${busTrackerScript}/bin/miami-bus-tracker";
        User = "nobody";
        Group = "nogroup";
      };
      path = with pkgs; [ curl xmlstarlet gnugrep gnused ];

      # Add time-based conditions if activeTimeStart is set
      unitConfig = mkIf (cfg.activeTimeStart != "") {
        ConditionTime =
          if cfg.activeTimeEnd != "" && cfg.activeTimeEnd < cfg.activeTimeStart
          then "${cfg.activeTimeStart}..23:59,00:00..${cfg.activeTimeEnd}"  # Crosses midnight
          else "${cfg.activeTimeStart}..${cfg.activeTimeEnd}";              # Normal range
      };
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

    # Notification service (only if notifications are enabled)
    systemd.services.miami-bus-notify = mkIf cfg.notification {
      description = "Send notification for approaching ${cfg.routeId} ${cfg.direction} bus";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${notificationScript}/bin/miami-bus-notify";
      };
      path = with pkgs; [ curl xmlstarlet gnugrep coreutils systemd sudo gawk libnotify gnused ];

      # Add time-based conditions if activeTimeStart is set
      unitConfig = mkIf (cfg.activeTimeStart != "") {
        ConditionTime =
          if cfg.activeTimeEnd != "" && cfg.activeTimeEnd < cfg.activeTimeStart
          then "${cfg.activeTimeStart}..23:59,00:00..${cfg.activeTimeEnd}"  # Crosses midnight
          else "${cfg.activeTimeStart}..${cfg.activeTimeEnd}";              # Normal range
      };
    };

    # Notification timer (only if notifications are enabled)
    systemd.timers.miami-bus-notify = mkIf cfg.notification {
      description = "Timer for Miami Bus Notification";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.interval;
        Unit = "miami-bus-notify.service";
      };
    };
  };
}
