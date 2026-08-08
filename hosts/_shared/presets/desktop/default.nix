{
  lib,
  pkgs,
  config,
  inputs,
  nixosModules,
  users,
  ...
}:
with lib; let
  fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    victor-mono
    nerd-fonts.noto
    nerd-fonts.hack
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.victor-mono
  ];
in {
  imports = [
    inputs.niri.nixosModules.default
    inputs.hyprland.nixosModules.default
    inputs.dms.nixosModules.default
    inputs.dms.nixosModules.greeter

    # Graphical-host modules. Importing a module activates it; a host can still
    # opt out with `<module>.enable = false` (lenovo does this for oom).
    nixosModules.features.app-images
    nixosModules.core.theming
    nixosModules.services.oom
    nixosModules.services.power-management
    nixosModules.programs.ld
    nixosModules.programs.one-password
  ];

  config = {
    # Flag graphical hosts so work/personal can gate their GUI-only packages.
    modules.presets.desktop.enable = true;

    # Boot splash on graphical hosts.
    boot.plymouth.enable = true;

    services = {
      # Enable CUPS to print documents.
      printing.enable = lib.mkDefault true;

      # Enable GVFS for file system access
      gvfs.enable = true;

      # Enable libinput for input devices
      libinput.enable = true;

      # Enable Avahi for network discovery
      avahi.enable = true;

      # Configure keymap in X11
      xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # Enable Smartd for disk monitoring
      smartd = {
        enable = false;
        autodetect = true;
      };
    };

    stylix.targets.kmscon.enable = false;

    # Install fonts
    fonts.packages = fonts;

    modules = {
      programs = {
        onePassword = {
          gitSignCommits = true;
          users = attrNames users;
          allowedCustomBrowsers = [
            ".zen-wrapped"
            "zen"
            "vivaldi"
            "vivaldi-bin"
            "vivaldi-stable"
            "vivaldi-snapshot"
          ];
        };
      };
    };

    # DankMaterialShell greeter — only on the niri hosts.
    programs.dms-greeter = mkIf config.modules.desktop.niri.enable {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/neoscode";
    };

    # Bleeding-edge Wayland packages (waybar, swww, portals, utils, ...).
    # Scoped to graphical desktop hosts — headless/WSL hosts don't need it and
    # would otherwise recompile the overlaid closure from source on every update.
    nixpkgs.overlays = [inputs.nixpkgs-wayland.overlay];

    # Binary caches so the overlay and the ghostty flake substitute instead of
    # building from source.
    nix.settings = {
      substituters = [
        "https://nixpkgs-wayland.cachix.org"
        "https://ghostty.cachix.org"
      ];
      trusted-public-keys = [
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      ];
    };

    environment = {
      # Graphical / physical-machine packages
      systemPackages = with pkgs; [
        wmctrl
        libinput
        wl-clipboard
        hunspell
        hunspellDicts.en_US
        bluez
        bluez-tools
      ];

      sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };
    };
  };
}
