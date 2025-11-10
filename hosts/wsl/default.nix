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

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  nixpkgs.hostPlatform = "x86_64-linux";
  home-manager.sharedModules = [./home.nix];

  # WSL Specific Configuration
  virtualisation.docker.enable = mkForce false;
  programs.git.config.programs.core.sshCommand = "ssh.exe";

  networking = {
    hostName = "wsl";
    firewall.enable = mkForce false;
    nameservers = mkForce [];
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
      uv
    ];
  };

  services.vscode-server = {
    enable = true;
    enableFHS = true;
    installPath = "$HOME/.local/share/vscode-server";
  };

  modules = {
    functionality.theming.enable = true;
    programs.ld.enable = true;

    presets = {
      base.enable = true;
      work.enable = true;
      personal.enable = true;
    };

    containers.settings = {
      backend = "docker";
      log-driver = "local";
    };
  };
}
