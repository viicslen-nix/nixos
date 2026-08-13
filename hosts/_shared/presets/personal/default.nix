{
  lib,
  pkgs,
  config,
  inputs,
  nixosModules,
  homeModules,
  ...
}:
with lib; {
  imports = [
    nixosModules.containers.homarr
    nixosModules.programs.qmk
  ];

  config = {
    home-manager.sharedModules = [
      # Shared AI tooling; ./ai configures it below.
      homeModules.programs.ai

      ({osConfig, ...}: {
        imports = [
          inputs.hunk.homeManagerModules.default
          ./ai
        ];

        programs.hunk = {
          enable = true;
          enableGitIntegration = true;
          settings = {
            mode = "auto";
            wrap_lines = false;
            line_numbers = true;
            transparent_background = false;
          };
        };

        # GUI screenshot tool — only on graphical hosts.
        services.flameshot.enable = mkIf osConfig.modules.presets.desktop.enable true;
      })
    ];

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
