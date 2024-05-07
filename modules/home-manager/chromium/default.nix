{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.features.chromium;
in {
  options.features.chromium = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable chromium";
    };
  };

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;

      extensions = [
        # Steps Recorder by Flonnect Capture
        {id = "hloeehlfligalbcbajlkjjdfngienilp";}
      ];
    };
  };
}
