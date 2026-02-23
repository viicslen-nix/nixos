{
  lib,
  pkgs,
  ...
}: {
  # home.packages = with pkgs; [
  #   legcord
  # ];

  modules = {
    services.impermanence = {
      enable = true;
      share = [
        "JetBrains"
        "keyrings"
        "direnv"
        "zoxide"
        "pnpm"
        "nvim"
      ];
      config = [
        "Lens"
        "Slack"
        "Ferdium"
        "Insomnia"
        "JetBrains"
        "GitHub Desktop"
        "github-copilot"
        "warp-terminal"
        "composer"
        "discord"
        "legcord"
        "direnv"
        "gcloud"
        "helm"
      ];
      cache = [
        "JetBrains"
        "carapace"
        "zoxide"
        "helm"
      ];
      directories = [
        ".pki"
        ".ssh"
        ".kube"
        ".java"
        ".gnupg"
        ".nixops"
        ".thunderbird"
      ];
      files = [
        ".env.aider"
        ".gitconfig"
        ".wakatime.cfg"
      ];
    };

    programs = {
      kitty.enable = true;
    };
  };

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
          "f1:40:12:eb:e0:e1:5d:4c:0e:45:61:e1:9f:7d:1c:9b:59:0b:91:ac:96:ea:a0:38:d3:8b:c9:f7:4e:9d:ad:46" = "dostov-dev";
        };
        clients = [
          {
            position = "top";
            hostname = "dostov-dev";
            ips = ["192.168.5.61"];
            port = 4242;
          }
        ];
      };
    };

    mimeApps = {
      # enable = true;
      associations.added = {
        "text/html" = "org.gnome.Epiphany.desktop;zen.desktop";
        "application/xhtml+xml" = "org.gnome.Epiphany.desktop;zen.desktop";
        "x-scheme-handler/sms" = "org.gnome.Shell.Extensions.GSConnect.desktop";
        "x-scheme-handler/tel" = "org.gnome.Shell.Extensions.GSConnect.desktop";
        "x-scheme-handler/http" = "org.gnome.Epiphany.desktop;zen.desktop";
        "x-scheme-handler/https" = "org.gnome.Epiphany.desktop;zen.desktop";
        "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
      };
      defaultApplications = {
        "text/html" = "zen.desktop";
        "application/xhtml+xml" = "zen.desktop";
        "x-scheme-handler/http" = "zen.desktop";
        "x-scheme-handler/https" = "zen.desktop";
        "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
      };
    };
  };

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "zen.desktop"
        "phpstorm.desktop"
        "ghostty.desktop"
        "legcord.desktop"
      ];
    };

    "org/gnome/shell/extensions/arcmenu" = {
      menu-button-border-color = lib.hm.gvariant.mkTuple [true "transparent"];
      menu-button-border-radius = lib.hm.gvariant.mkTuple [true 10];
    };

    "org/gnome/desktop/wm/preferences".button-layout = lib.mkForce ":minimize,maximize,close";
  };

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,2560x1600@60,0x0,1.6"
    ];
  };

  home.file.".config/hypr/pyprland.toml".text = lib.mkAfter ''
    [monitors.placement."G276HL"]
    topOf = "eDP-1"

    [monitors.placement."G274F"]
    leftOf = "eDP-1"

    [monitors.placement."Acer CB281HK"]
    topOf = "G274F"
    scale = 1.875000
  '';

  # programs.hyprpanel.settings.layout = {
  #   "bar.layouts" = {
  #     "0" = {
  #       left = [
  #         "dashboard"
  #         "workspaces"
  #         "windowtitle"
  #         "hypridle"
  #         "submap"
  #       ];
  #       middle = [
  #         "cpu"
  #         "ram"
  #         "storage"
  #       ];
  #       right = [
  #         "systray"
  #         "volume"
  #         "bluetooth"
  #         "network"
  #         "battery"
  #         "clock"
  #         "notifications"
  #         "power"
  #       ];
  #     };
  #   };
  # };

  # home.file."/home/neoscode/.config/mimeapps.list".force = lib.mkForce true;
}
