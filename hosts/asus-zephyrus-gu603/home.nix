{lib, pkgs, ...}: {
  modules.functionality.impermanence = {
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
        "tinkerwell"
        "composer"
        "discord"
        "legcord"
        "direnv"
        "gcloud"
        "helm"
        "op"
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

    xdg = {
      configFile."gh/hosts.yml".source = (pkgs.formats.yaml {}).generate "hosts.yml" {
        "github.com" = {
          user = "viicslen";
          git_protocol = "https";
          users = {
            viicslen = "";
          };
        };
      };

      mimeApps = {
        enable = true;
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

    home.file."/home/neoscode/.config/mimeapps.list".force = lib.mkForce true;
}
