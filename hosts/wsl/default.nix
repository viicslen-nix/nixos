{
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.vscode-server.nixosModules.default
  ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";
  home-manager.sharedModules = [./home.nix];

  networking = {
    hostName = "wsl";
    firewall.enable = mkForce false;
  };

  wsl = {
    enable = true;
    defaultUser = "neoscode";
    interop.register = true;
    docker-desktop.enable = true;
    startMenuLaunchers = true;
    useWindowsDriver = true;
    extraBin = [
      {
        src = lib.getExe pkgs.git;
      }
      {
        src = lib.getExe pkgs.bashInteractive;
      }
    ];
  };

  i18n.extraLocaleSettings = {
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_COLLATE = "en_US.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
    LC_ADDRESS = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
  };

  environment = {
    shellAliases = {
      op = "op.exe";
      ssh = "ssh.exe";
      ssh-add = "ssh-add.exe";
    };

    systemPackages = with pkgs; [
      jetbrains.webstorm
      jetbrains.phpstorm
      jetbrains.jdk
    ];
  };

  programs = {
    nix-ld.enable = true;
    git.config.programs.core.sshCommand = "ssh.exe";
  };

  services.vscode-server.enable = true;

  modules = {
    presets = {
      base.enable = true;
      work.enable = true;
      personal.enable = true;
    };

    functionality.theming.enable = true;
    containers.settings.log-driver = "local";
  };
}
