{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib; let
  cfg = config.features.hyprland;
  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.features.hyprland = {
    enable = mkEnableOption (mdDoc "hyprland");

    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to configure hyprland for";
    };
  };

  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = mkIf cfg.enable (mkMerge [
    {
      programs = {
        hyprland = {
          enable = true;
          xwayland.enable = true;
        };

        waybar.enable = true;
      };

      environment.systemPackages = with pkgs; [
        swaynotificationcenter
        hyprpaper
        wlroots
        wofi
      ];

      nix.settings = {
        substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      };
    }
    (mkIf homeManagerLoaded {
      home-manager = {
        users.${cfg.user} = {
          imports = [
            inputs.hyprland.homeManagerModules.default
            inputs.hyprlock.homeManagerModules.default
            ./hyprpaper.nix
            ./settings.nix
            ./hyprlock.nix
            ./hypridle.nix
            ./wlogout.nix
            ./binds.nix
            ./rules.nix
          ];

          home.packages = with pkgs; [
            # screenshot
            grim
            slurp

            # utils
            self.packages.${pkgs.system}.wl-ocr
            wl-clipboard
            wl-screenrec
            wlr-randr

            inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
          ];

          # make stuff work on wayland
          home.sessionVariables = {
            QT_QPA_PLATFORM = "wayland";
            SDL_VIDEODRIVER = "wayland";
            XDG_SESSION_TYPE = "wayland";
          };

          wayland.windowManager.hyprland = {
            enable = true;

            # settings = {
            #   monitor = ",preferred,auto,auto";

            #   env = "XCURSOR_SIZE,24";

            #   "$menu" = "wofi --show drun";
            #   "$fileManager" = "nautilus";
            #   "$terminal" = "warp-terminal";

            #   input = {
            #     kb_layout = "us";

            #     follow_mouse = 1;

            #     touchpad = {
            #       natural_scroll = false;
            #     };

            #     sensitivity = 0;
            #   };

            #   general = {
            #     # See https://wiki.hyprland.org/Configuring/Variables/ for more

            #     gaps_in = 5;
            #     gaps_out = 20;
            #     border_size = 2;

            #     layout = "dwindle";

            #     # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
            #     allow_tearing = false;
            #   };

            #   decoration = {
            #     # See https://wiki.hyprland.org/Configuring/Variables/ for more

            #     rounding = 10;

            #     blur = {
            #       enabled = true;
            #       size = 3;
            #       passes = 1;

            #       vibrancy = 0.1696;
            #     };

            #     drop_shadow = true;
            #     shadow_range = 4;
            #     shadow_render_power = 3;
            #     col.shadow = "rgba(1a1a1aee)";
            #   };

            #   animations = {
            #     enabled = true;

            #     # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

            #     bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

            #     animation = [
            #       "windows, 1, 7, myBezier"
            #       "windowsOut, 1, 7, default, popin 80%"
            #       "border, 1, 10, default"
            #       "borderangle, 1, 8, default"
            #       "fade, 1, 7, default"
            #       "workspaces, 1, 6, default"
            #     ];
            #   };

            #   dwindle = {
            #     # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
            #     pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            #     preserve_split = true; # you probably want this
            #   };

            #   "$mainMod" = "SUPER";

            #   bind = [
            #     # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
            #     "$mainMod, Q, exec, $terminal"
            #     "$mainMod, C, killactive,"
            #     "$mainMod, M, exit,"
            #     "$mainMod, E, exec, $fileManager"
            #     "$mainMod, V, togglefloating,"
            #     "$mainMod, R, exec, $menu"
            #     "$mainMod, P, pseudo, # dwindle"
            #     "$mainMod, J, togglesplit, # dwindle"

            #     # Move focus with mainMod + arrow keys
            #     "$mainMod, left, movefocus, l"
            #     "$mainMod, right, movefocus, r"
            #     "$mainMod, up, movefocus, u"
            #     "$mainMod, down, movefocus, d"

            #     # Switch workspaces with mainMod + [0-9]
            #     "$mainMod, 1, workspace, 1"
            #     "$mainMod, 2, workspace, 2"
            #     "$mainMod, 3, workspace, 3"
            #     "$mainMod, 4, workspace, 4"
            #     "$mainMod, 5, workspace, 5"
            #     "$mainMod, 6, workspace, 6"
            #     "$mainMod, 7, workspace, 7"
            #     "$mainMod, 8, workspace, 8"
            #     "$mainMod, 9, workspace, 9"
            #     "$mainMod, 0, workspace, 10"

            #     # Move active window to a workspace with mainMod + SHIFT + [0-9]
            #     "$mainMod SHIFT, 1, movetoworkspace, 1"
            #     "$mainMod SHIFT, 2, movetoworkspace, 2"
            #     "$mainMod SHIFT, 3, movetoworkspace, 3"
            #     "$mainMod SHIFT, 4, movetoworkspace, 4"
            #     "$mainMod SHIFT, 5, movetoworkspace, 5"
            #     "$mainMod SHIFT, 6, movetoworkspace, 6"
            #     "$mainMod SHIFT, 7, movetoworkspace, 7"
            #     "$mainMod SHIFT, 8, movetoworkspace, 8"
            #     "$mainMod SHIFT, 9, movetoworkspace, 9"
            #     "$mainMod SHIFT, 0, movetoworkspace, 10"

            #     # Example special workspace (scratchpad)
            #     "$mainMod, S, togglespecialworkspace, magic"
            #     "$mainMod SHIFT, S, movetoworkspace, special:magic"

            #     # Scroll through existing workspaces with mainMod + scroll
            #     "$mainMod, mouse_down, workspace, e+1"
            #     "$mainMod, mouse_up, workspace, e-1"

            #     # Move/resize windows with mainMod + LMB/RMB and dragging
            #     "$mainMod, mouse:272, movewindow"
            #     "$mainMod, mouse:273, resizewindow"
            #   ];
            # };
          };
        };
      };
    })
  ]);
}
