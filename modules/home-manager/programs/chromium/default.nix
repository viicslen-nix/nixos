{
  lib,
  config,
  ...
}:
with lib; let
  name = "chromium";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
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
