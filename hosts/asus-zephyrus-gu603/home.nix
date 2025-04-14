{
  lib,
  pkgs,
  ...
}: {
  # home.packages = with pkgs; [
  #   legcord
  # ];

  modules = {
    functionality.impermanence = {
      enable = true;
      share = [
        "Steam"
        "JetBrains"
        "keyrings"
        "direnv"
        "zoxide"
        "mkcert"
        "pnpm"
        "nvim"
        "atuin"

        # Plasma
        "baloo"
        "dolphin"
        "kactivitymanagerd"
        "kate"
        "klipper"
        "konsole"
        "kscreen"
        "kwalletd"
        "kxmlgui5"
        "sddm"
      ];
      config = [
        "Lens"
        "Code"
        "Slack"
        "Insomnia"
        "JetBrains"
        "1Password"
        "Tinkerwell"
        "Mullvad VPN"
        "GitHub Desktop"
        "microsoft-edge"
        "github-copilot"
        "warp-terminal"
        "tinkerwell"
        "lan-mouse"
        "composer"
        "discord"
        "legcord"
        "direnv"
        "gcloud"
        "helm"
        "op"

        # Plasma
        "gtk-3.0"
        "gtk-4.0"
        "KDE"
        "kde.org"
        "plasma-workspace"
        "xsettingsd"
      ];
      cache = [
        "JetBrains"
        "starship"
        "carapace"
        "zoxide"
        "atuin"
        "helm"
      ];
      directories = [
        ".pki"
        ".ssh"
        ".zen"
        ".kube"
        ".java"
        ".gnupg"
        ".steam"
        ".nixops"
        ".vscode"
        ".docker"
        ".mozilla"
        ".thunderbird"
        ".tmux/resurrect"
        ".kde"
      ];
      files = [
        ".env.aider"
        ".gitconfig"
        ".ideavimrc"
        ".zsh_history"
        ".wakatime.cfg"
        ".config/background"
        ".config/monitors.xml"
      ];
    };

    programs = {
      # ray.enable = true;
      kitty.enable = true;
      # ghostty.enable = true;
      # tinkerwell.enable = true;
      lan-mouse = {
        enable = true;
        autostart = true;
      };
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
        "text/html" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
        "application/xhtml+xml" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
        "x-scheme-handler/sms" = "org.gnome.Shell.Extensions.GSConnect.desktop";
        "x-scheme-handler/tel" = "org.gnome.Shell.Extensions.GSConnect.desktop";
        "x-scheme-handler/http" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
        "x-scheme-handler/https" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
        "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
      };
      defaultApplications = {
        "text/html" = "microsoft-edge.desktop";
        "application/xhtml+xml" = "microsoft-edge.desktop";
        "x-scheme-handler/http" = "microsoft-edge.desktop";
        "x-scheme-handler/https" = "microsoft-edge.desktop";
        "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
      };
    };
  };

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "microsoft-edge.desktop"
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

  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,2560x1600@60,0x0,1.6"
  ];

  home.file.".config/hypr/pyprland.toml".text = lib.mkAfter ''
    [monitors.placement."G276HL"]
    topOf = "eDP-1"

    [monitors.placement."G274F"]
    leftOf = "eDP-1"

    [monitors.placement."Acer CB281HK"]
    topOf = "DP-1"
    scale = 1.875000
  '';

  # home.file."/home/neoscode/.config/mimeapps.list".force = lib.mkForce true;
}
