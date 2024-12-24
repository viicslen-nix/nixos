{
  lib,
  config,
  ...
}:
with lib; let
  name = "impermanence";
  namespace = "features";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config =
    mkIf cfg.enable {
    };
}
