{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "impermanence";
  namespace = "features";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "impermanence");
    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to use in the impermanence home path";
    };
    config = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Config directories to save after reboot";
    };
    share = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Share directories to save after reboot";
    };
    directories = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Directories to save after reboot";
    };
    files = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Files to save after reboot";
    };
  };

  imports = mkIf cfg.enable [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  config.home.persistence."/persist/home/${cfg.user}" = mkIf cfg.enable {
    directories = [
      "Development"
      "Documents"
      "Downloads"
      "Pictures"
      "Desktop"
      "Videos"
      "Music"
    ] 
    ++ lists.forEach cfg.config (dir: ".config/${dir}")
    ++ lists.forEach cfg.share (dir: ".local/share/${dir}")
    ++ cfg.directories;

    files = [] ++ cfg.files;

    allowOther = true;
  };
}
