{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.features.sound;
in {
  options.features.sound = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable sound support";
    };
  };

  config = mkIf cfg.enable {
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };
  };
}
