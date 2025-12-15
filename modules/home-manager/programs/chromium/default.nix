{
  lib,
  config,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "chromium";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.chromium = {
        enable = true;

        extensions = [
          # Steps Recorder by Flonnect Capture
          {id = "hloeehlfligalbcbajlkjjdfngienilp";}
        ];
      };
    }
    (mkPersistence config {
      config = ["chromium"];
    })
  ]);
}
