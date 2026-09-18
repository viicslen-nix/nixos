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
  caches = import ../../../../caches.nix {inherit lib;};

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
    # Family "Symbols Nerd Font Mono" — what nerd-icons (Emacs) asks for by
    # name. The patched fonts above carry the glyphs but not that family name.
    nerd-fonts.symbols-only
    # all-the-icons' font set (treemacs icon theme); the package's own
    # `all-the-icons-install-fonts' writes into $HOME, so install it here.
    emacs-all-the-icons-fonts
  ];
in {
  imports = [
    inputs.niri.nixosModules.default
    inputs.hyprland.nixosModules.default
    inputs.dms.nixosModules.default
    inputs.dms.nixosModules.greeter

    # Graphical-host modules. Importing a module activates it; a host can still
    # opt out with `<module>.enable = false` (lenovo does this for oom).
    nixosModules.desktop.shell
    nixosModules.desktop.monitors
    nixosModules.hardware.bluetooth
    nixosModules.features.app-images
    nixosModules.core.sound
    nixosModules.core.theming
    nixosModules.hardware.bluetooth
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

    # Shared grub-on-EFI layout; every leaf is a default so a host can override one.
    boot.loader = {
      efi.efiSysMountPoint = mkDefault "/boot/efi";
      grub = {
        enable = mkDefault true;
        device = mkDefault "nodev";
        efiSupport = mkDefault true;
        configurationLimit = mkDefault 10;
      };
    };

    services = {
      # Enable CUPS to print documents.
      printing.enable = lib.mkDefault true;

      # Enable GVFS for file system access
      gvfs.enable = true;

      # Enable libinput for input devices
      libinput.enable = true;

      # Enable Avahi for network discovery
      avahi = {
        enable = true;
        # Without nssmdns4 avahi runs but `.local` never resolves — network printers stay invisible.
        nssmdns4 = true;
        openFirewall = true;
      };

      # Configure keymap in X11
      xserver.xkb = {
        layout = "us";
        variant = "";
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

    # dms's NixOS half; its home-manager half gates itself on the same option.
    dms.autoEnable = config.modules.desktop.shell == "dms";

    # DankMaterialShell greeter — the greeter is shell-independent, so it stays
    # on whichever shell `modules.desktop.shell` selects.
    programs.dms-greeter = mkIf config.modules.desktop.niri.enable {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/${head (attrNames users)}";
    };

    # Keep this out of `base` — headless hosts would rebuild the whole closure.
    nixpkgs.overlays = [inputs.nixpkgs-wayland.overlay];

    # Add a cache in caches.nix with scope = "desktop", never here.
    nix.settings = {
      substituters = caches.substituters "desktop";
      trusted-public-keys = caches.trustedKeys "desktop";
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
