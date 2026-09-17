{
  flake.modules.nixos.miami-bus-tracker = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.services.miami-bus-tracker;
      bins = pkgs.callPackage ./packages.nix {inherit (cfg) routeId direction stopId notifyMinutes apiKey;};
    in {
      options.services.miami-bus-tracker = {
        enable = mkEnabledOption "Miami-Dade Transit Bus Tracker";

        routeId = mkOption {
          type = types.str;
          default = "836";
          description = "The route ID to track.";
        };

        direction = mkOption {
          type = types.str;
          default = "Westbound";
          example = "Eastbound";
          description = "Direction name as the API spells it (Northbound, Southbound, Eastbound, Westbound).";
        };

        stopId = mkOption {
          type = types.str;
          default = "3096";
          description = "The Stop ID to track; discover it with miami-find-stop.";
        };

        apiKey = mkOption {
          type = types.str;
          default = "P98EG7NGA9A02NAE00Y";
          description = "x-api-key for the county transit API; the default is the public key embedded in miamidade.gov's own tracker page.";
        };

        interval = mkOption {
          type = types.str;
          default = "5min";
          description = "How often to check for bus arrivals (systemd timer interval).";
        };

        notification = mkOption {
          type = types.bool;
          default = false;
          description = "Send a desktop notification when a bus is approaching.";
        };

        overlay = mkOption {
          type = types.bool;
          default = true;
          description = "Also pop up a corner map overlay with the live bus position (requires notification).";
        };

        notifyMinutes = mkOption {
          type = types.int;
          default = 5;
          description = "Notify when the next bus is within this many minutes.";
        };

        activeTimeStart = mkOption {
          type = types.str;
          default = "";
          example = "17:00";
          description = "Start of the active checking window (HH:MM); empty checks at all times.";
        };

        activeTimeEnd = mkOption {
          type = types.str;
          default = "23:59";
          example = "23:00";
          description = "End of the active checking window (HH:MM); may be before the start to cross midnight.";
        };
      };

      config = mkIf cfg.enable {
        environment.systemPackages = [bins.tracker bins.findStop] ++ optional cfg.overlay bins.overlay;

        systemd = {
          services.miami-bus-notify = mkIf cfg.notification {
            description = "Send notification for approaching ${cfg.routeId} ${cfg.direction} bus";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${bins.notify}/bin/miami-bus-notify";
            };
            unitConfig = mkIf (cfg.activeTimeStart != "") {
              ConditionTime =
                if cfg.activeTimeEnd != "" && cfg.activeTimeEnd < cfg.activeTimeStart
                then "${cfg.activeTimeStart}..23:59,00:00..${cfg.activeTimeEnd}"
                else "${cfg.activeTimeStart}..${cfg.activeTimeEnd}";
            };
          };

          timers.miami-bus-notify = mkIf cfg.notification {
            description = "Timer for Miami Bus Notification";
            wantedBy = ["timers.target"];
            timerConfig = {
              OnBootSec = "1min";
              OnUnitActiveSec = cfg.interval;
              Unit = "miami-bus-notify.service";
            };
          };

          # Started by miami-bus-notify inside each user's session; it exits on its own once the bus is gone.
          user.services.miami-bus-overlay = mkIf (cfg.notification && cfg.overlay) {
            description = "Live map overlay for the approaching ${cfg.routeId} ${cfg.direction} bus";
            unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
            serviceConfig.ExecStart = "${bins.overlay}/bin/miami-bus-overlay";
          };
        };
      };
    };
}
