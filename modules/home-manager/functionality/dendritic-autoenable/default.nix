{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options.dendritic.autoEnable = {
    global = mkOption {
      type = types.bool;
      default = true;
      description = "Baseline auto-enable behavior for imported Home Manager modules.";
    };

    modules = mkOption {
      type = types.attrsOf types.bool;
      default = {};
      description = "Per-module auto-enable overrides keyed by stable module id.";
    };
  };

  config = {};
}
