{
  lib,
  config,
  ...
}:
with lib; let
  name = "starship";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "starship");
  };

  config.programs.starship = mkIf cfg.enable {
    enable = true;

    settings = builtins.fromTOML (builtins.unsafeDiscardStringContext (builtins.readFile ./config.toml));
  };
}