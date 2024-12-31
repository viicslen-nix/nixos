{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  name = "kanata";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "The users to add to the uinput group";
    };
  };

  config =mkIf cfg.enable {
    # Enable the uinput module
    boot.kernelModules = [ "uinput" ];

    # Enable uinput
    hardware.uinput.enable = true;

    # Set up udev rules for uinput
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    # Ensure the uinput group exists
    users.groups.uinput = { };

    # Add the Kanata service user to necessary groups
    systemd.services.kanata-internalKeyboard.serviceConfig = {
      SupplementaryGroups = [
        "input"
        "uinput"
      ];
    };

    environment.systemPackages = with pkgs; [
      kanata
    ];

    services.kanata = {
      enable = true;
      keyboards = {
        default = {
          devices = [
            "/dev/input/by-id/usb-0461_USB_Wired_Keyboard-event-kbd"
          ];
          extraDefCfg = "process-unmapped-keys yes";
          config = ''
            (defsrc
              caps a s d f j k l ;
              lsft
            )
            (defvar
              tap-time 250
              hold-time 300
            )

            (defalias
              escshift (tap-hold 100 100 esc lsft)
              a (tap-hold $tap-time $hold-time a lmet)
              s (tap-hold $tap-time $hold-time s lalt)
              d (tap-hold $tap-time $hold-time d lsft)
              f (tap-hold $tap-time $hold-time f lctl)
              j (tap-hold $tap-time $hold-time j rctl)
              k (tap-hold $tap-time $hold-time k rsft)
              l (tap-hold $tap-time $hold-time l ralt)
              ; (tap-hold $tap-time $hold-time ; rmet)
            )

            (deflayer base
              @escshift @a @s @d @f @j @k @l @;
              lctl
            )
          '';
        };
      };
    };

    users.users = lib.genAttrs cfg.users (_user: {
      extraGroups = ["uinput"];
    });
  };
}
