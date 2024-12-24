{
  lib,
  config,
  ...
}:
with lib; let
  name = "sound";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable sound support";
    };
  };

  config = mkIf cfg.enable {
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber = {
          enable = true;
          extraConfig.bluetoothEnhancements = {
            "monitor.bluez.properties" = {
                "bluez5.enable-sbc-xq" = true;
                "bluez5.enable-msbc" = true;
                "bluez5.enable-hw-volume" = true;
                "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
            };
          };
        };
      };
    };
  };
}
