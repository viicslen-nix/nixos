{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "zellij";
  namespace = "features";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name}.enable = mkEnableOption (mdDoc "zellij");

  config = {
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      settings = {
        ui = {
          pane_frames = {
            rounded_corners = true;
          };
        };
      };
    };
  };
}
