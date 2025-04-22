{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  home.autostart = [
    pkgs.jetbrains-toolbox
  ];

  xdg = {
    configFile = {
      "gh/hosts.yml".source = (pkgs.formats.yaml {}).generate "hosts.yml" {
        "github.com" = {
          user = "viicslen";
          git_protocol = "https";
          users = {
            viicslen = "";
          };
        };
      };

      "lan-mouse/config.toml".source = (pkgs.formats.toml {}).generate "config.toml" {
        authorized_fingerprints = {
          "4e:c7:84:e6:69:2a:e9:4b:93:6e:44:52:fd:f1:94:2c:ce:73:69:5f:6a:3a:96:c0:da:e8:50:73:ee:3e:4c:b7" = "asus-zephyrus-gu603";
        };
        clients = [
          {
            position = "bottom";
            hostname = "asus-zephyrus-gu603";
            ips = ["192.168.5.111"];
            port = 4242;
          }
        ];
      };
    };

    mimeApps = {
      # enable = true;
      associations.added = {
        "text/html" = "microsoft-edge.desktop";
        "application/xhtml+xml" = "microsoft-edge.desktop";
        "x-scheme-handler/http" = "microsoft-edge.desktop";
        "x-scheme-handler/https" = "microsoft-edge.desktop";
        "x-scheme-handler/sms" = "org.gnome.Shell.Extensions.GSConnect.desktop";
        "x-scheme-handler/tel" = "org.gnome.Shell.Extensions.GSConnect.desktop";
      };
      defaultApplications = {
        "text/html" = "microsoft-edge.desktop";
        "application/xhtml+xml" = "microsoft-edge.desktop";
        "x-scheme-handler/http" = "microsoft-edge.desktop";
        "x-scheme-handler/https" = "microsoft-edge.desktop";
      };
    };
  };

  home.file.".config/hypr/pyprland.toml".text = lib.mkAfter ''
    [monitors.placement."LW9AA0048525"]
    rightOf = "DP-1"
    transform = 3
  '';

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1, 1920x1080@59.99, 0x0, 1, vrr, 0"
      "DP-2, 1920x1080@59.99, 1920x0, 1, transform, 3, vrr, 0"
      ", preferred, auto, 1"
    ];

    cursor.no_hardware_cursors = 1;
  };

  modules = {
    # functionality.home-manager.overrideBackups = true;

    programs = {
      ray.enable = true;
      kitty.enable = true;
      tinkerwell.enable = true;
    };
  };

  stylix.targets.kde.enable = false;
}
