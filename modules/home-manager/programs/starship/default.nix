{
  lib,
  config,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "starship";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "starship");
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.starship = {
        enable = true;

        settings =
          builtins.fromTOML (builtins.unsafeDiscardStringContext (builtins.readFile ./config.toml))
          // {
            palette = mkForce "main";
          };
      };
    }
    (persistence.mkPersistence config {
      cache = ["starship"];
    })
  ]);
}
