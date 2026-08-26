{
  lib,
  pkgs,
  config,
  nixosModules,
  ...
}:
with lib; {
  imports = [
    nixosModules.containers.homarr
    nixosModules.programs.qmk
  ];

  config = {
    home-manager.sharedModules = [./home.nix];

    # Optimization: Prevent systemd from waiting for network online
    # (Optional but recommended for faster boot with VPNs)
    systemd.network.wait-online.enable = false;
    boot.initrd.systemd.network.wait-online.enable = false;

    environment.systemPackages = with pkgs;
      [
        nix-alien
        nix-init
        graphviz
        asciinema
        yazi
        android-tools
        nchat
        # Explicitly qualified: `inputs` is now a module argument, which shadows
        # the `pkgs.inputs` alias that `with pkgs;` used to resolve these to.
        pkgs.inputs.nixvim.default
        pkgs.inputs.emacs.default
        pkgs.inputs.packages.scripts.git-carve-submodule
        dict
      ]
      # GUI apps only on graphical hosts (excluded on WSL/headless).
      # ferdium lives in the work preset, so it isn't duplicated here.
      ++ lib.optionals config.modules.presets.desktop.enable [
        ytmdesktop
        scrcpy
        qtscrcpy

        # Shared personal GUI apps (were duplicated across the desktop hosts)
        obsidian
        legcord
        drawing
        drawio
        kooha
      ];

    services = {
      dictd.enable = mkDefault true;
    };

    programs = {
      localsend.enable = mkDefault true;
    };
  };
}
