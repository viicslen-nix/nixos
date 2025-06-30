{
  lib,
  config,
  ...
}:
with lib; let
  name = "ideavim";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config.home.file.".ideavimrc" = mkIf cfg.enable {
    source = ./ideavimrc;
  };
}
