{
  lib,
  config,
  ...
}:
with lib; let
  name = "ghostty";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      inputs.ghostty.default
    ];

    xdg.configFile."ghostty/config".source = ./config;
  };
}
