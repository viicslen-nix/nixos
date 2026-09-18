{
  lib,
  pkgs,
  users,
  config,
  nixosModules,
  ...
}:
with lib; let
  desktop = config.modules.presets.desktop.enable;
in {
  imports = [
    nixosModules.containers.homarr
    nixosModules.programs.qmk
  ];

  config = {
    home-manager.sharedModules = [./home.nix];

    users.users = mapAttrs (_: _: {extraGroups = ["adbusers"];}) users;

    modules = {
      programs.qmk.enable = desktop;
      containers.homarr.enable = desktop;
    };

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
        pkgs.inputs.packages.scripts.git-carve-submodule
        dict
      ]
      # GUI apps only on graphical hosts (excluded on WSL/headless).
      ++ lib.optionals desktop [
        pkgs.inputs.emacs.default
        ytmdesktop
        scrcpy
        qtscrcpy
        obsidian
        legcord
        discord
        ferdium
        drawing
        drawio
        kooha
        luakit
        meld
        github-desktop
        sublime-merge
      ];

    services = {
      dictd.enable = mkDefault true;
    };

    programs = {
      localsend.enable = mkDefault desktop;
    };
  };
}
