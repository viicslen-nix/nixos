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
    ../../users/neoscode
  ];

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
        src = lib.getExe pkgs.bash;
      }
    ];
  };

  networking = {
    hostName = "wsl";
    firewall.enable = mkForce false;
  };

  programs.git.config.programs.core.sshCommand = "ssh.exe";
  services.vscode-server.enable = true;

  environment.shellAliases = {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
  };

  modules = {
    functionality = {
      oom.enable = mkForce false;
      theming.enable = true;
      appImages.enable = true;

      network.hosts = mkForce {};

      impermanence = {
        enable = false;
        directories = [
          "/etc/mullvad-vpn"
          "/etc/gdm"
        ];
      };
    };

    presets = {
      base.enable = true;
      work.enable = true;
      personal.enable = true;
    };
  };

  system.stateVersion = "25.05";
}
