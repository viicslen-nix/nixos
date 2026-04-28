{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "zed";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.zed = {
        enable = true;
        enableMcpIntegration = true;
        mutableUserKeymaps = false;
      };
    }
    (persistence.mkPersistence config {
      config = ["Zed"];
    })
  ]);
}
