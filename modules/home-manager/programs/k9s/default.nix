{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "k9s";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name}.enable = mkEnableOption (mdDoc "zellij");

  config = mkIf cfg.enable {
    programs.k9s = {
      enable = true;

      settings = {
        ui = {
          logoless = true;
        };
      };

      hotKeys = {
        "shift-v" = {
          shortCut = "Shift-V";
          description = "Filter out completed pods";
          command = "pods /!Completed";
          keepHistory = true;
        };
      };
    };
  };
}
