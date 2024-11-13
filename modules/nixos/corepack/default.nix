{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "corepack";
  namespace = "modules";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    strict = mkEnableOption (mdDoc "Enable strict mode");
    autoPin = mkEnableOption (mdDoc "Enable auto pin");
    projectSpec = mkEnableOption (mdDoc "Enable project spec");
    package = mkOption {
      type = types.package;
      default = pkgs.corepack;
      description = "The corepack package to use";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        COREPACK_ENABLE_STRICT = if cfg.strict then "1" else "0";
        COREPACK_ENABLE_AUTO_PIN = if cfg.autoPin then "1" else "0";
        COREPACK_ENABLE_PROJECT_SPEC = if cfg.projectSpec then "1" else "0";
      };

      systemPackages = [ cfg.package ];
    };
  };
}
