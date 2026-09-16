{
  lib,
  pkgs,
  osConfig,
  homeModules,
  ...
}: {
  imports = with homeModules; [
    programs.kitty
  ];

  modules = {
    functionality.impermanence = {
      enable = false;
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

  wayland.windowManager.hyprland.settings = lib.mkIf osConfig.programs.hyprland.enable {
    monitor = [
      {
        output = "eDP-1";
        mode = "2560x1600@60";
        position = "0x0";
        scale = 1.6;
      }
      # desc: is a prefix match on "make model serial" — don't drop the make.
      {
        output = "desc:Acer Technologies G276HL";
        position = "0x-1080";
        scale = 1;
      }
      {
        output = "desc:Microstep G274F";
        position = "-1920x0";
        scale = 1;
      }
      {
        output = "desc:Acer Technologies Acer CB281HK";
        position = "-1920x-1152";
        scale = 1.875;
      }
    ];
  };
}
