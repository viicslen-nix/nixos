{
  lib,
  pkgs,
  inputs,
  ...
}: {
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
}
