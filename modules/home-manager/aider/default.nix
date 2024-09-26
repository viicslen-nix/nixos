{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "aider";
  namespace = "programs";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      aider-chat
    ];

    home.file.".aider.conf.yml".text = ''
    model: gemini/gemini-1.5-pro-exp-0827
    env-file: .env.aider
    check-update: false
    dark-mode: true
    vim: true
    '';
  };
}
