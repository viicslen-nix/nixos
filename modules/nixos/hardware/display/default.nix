{
  lib,
  config,
  ...
}:
with lib; let
  name = "display";
  namespace = "hardware";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    resolution = mkOption {
      type = types.str;
      default = "1920x1080";
      description = "The resolution to use";
    };
    refreshRate = mkOption {
      type = types.str;
      default = "60";
      description = "The refresh rate to use";
    };
    port = mkOption {
      type = types.str;
      default = "HDMI";
      description = "The port to use";
    };
  };

  config = mkIf cfg.enable {
    # Patch for 165hz display
    boot.kernelParams = ["video=${cfg.port}:${cfg.resolution}@${cfg.refreshRate}"];

    services.xserver = {
      enable = true;

      exportConfiguration = true;
      displayManager.sessionCommands = ''
        xrandr --newmode "${cfg.resolution}_${cfg.refreshRate}.00" 1047.00 2560 2800 3080 3600  1600 1603 1609 1763 -hsync +vsync
        xrandr --addmode ${cfg.port} "${cfg.resolution}_${cfg.refreshRate}.00"
        xrandr --output ${cfg.port} --mode ${cfg.resolution} --rate ${cfg.refreshRate}
      '';
    };
  };
}
