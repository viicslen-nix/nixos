{
  lib,
  config,
  inputs,
  ...
}:
with lib; let
  name = "impermanence";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "impermanence");

    persistencePath = mkOption {
      type = types.str;
      default = "/persist";
      description = "Root path where to store persistent files and directories";
    };

    share = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Share directories to keep after reboot";
    };
    config = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Config directories to keep after reboot";
    };
    cache = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Cache directories to keep after reboot";
    };
    directories = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Directories to keep after reboot";
    };
    files = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Files to keep after reboot";
    };
  };

  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  config = mkIf cfg.enable {
    home.persistence."${cfg.persistencePath}/${config.home.homeDirectory}" = {
      directories = concatLists [
        (lists.forEach cfg.share (dir: ".local/share/${dir}"))
        (lists.forEach cfg.config (dir: ".config/${dir}"))
        (lists.forEach cfg.cache (dir: ".cache/${dir}"))
        cfg.directories
        [
          {
            directory = "Development";
            method = "symlink";
          }
          {
            directory = ".nix";
            method = "symlink";
          }
          "Documents"
          "Downloads"
          "Pictures"
          "Desktop"
          "Videos"
          "Music"
        ]
      ];

      files = [] ++ cfg.files;

      allowOther = true;
    };
  };
}
