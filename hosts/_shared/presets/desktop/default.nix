{
  lib,
  pkgs,
  config,
  inputs,
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
  ];

  config = {
    # Flag graphical hosts so work/personal can gate their GUI-only packages.
    modules.presets.desktop.enable = true;

    modules.features.appImages.enable = true;

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
      core.theming.enable = true;

      services = {
        # mkDefault so a host (e.g. the Jovian handheld) can opt out.
        oom.enable = lib.mkDefault true;
        powerManagement.enable = lib.mkDefault true;
      };

      programs = {
        # nix-ld for running non-Nix / AppImage binaries.
        ld.enable = true;

        onePassword = {
          enable = true;
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
