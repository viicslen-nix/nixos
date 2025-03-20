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

        # Plasma
        ".config/akregatorrc"
        ".config/baloofileinformationrc"
        ".config/baloofilerc"
        ".config/bluedevilglobalrc"
        ".config/device_automounter_kcmrc"
        ".config/dolphinrc"
        ".config/filetypesrc"
        ".config/gtkrc"
        ".config/gtkrc-2.0"
        ".config/gwenviewrc"
        ".config/kactivitymanagerd-pluginsrc"
        ".config/kactivitymanagerd-statsrc"
        ".config/kactivitymanagerd-switcher"
        ".config/kactivitymanagerdrc"
        ".config/katemetainfos"
        ".config/katerc"
        ".config/kateschemarc"
        ".config/katevirc"
        ".config/kcmfonts"
        ".config/kcminputrc"
        ".config/kconf_updaterc"
        ".config/kded5rc"
        ".config/kdeglobals"
        ".config/kgammarc"
        ".config/kglobalshortcutsrc"
        ".config/khotkeysrc"
        ".config/kmixrc"
        ".config/konsolerc"
        ".config/kscreenlockerrc"
        ".config/ksmserverrc"
        ".config/ksplashrc"
        ".config/ktimezonedrc"
        ".config/kwinrc"
        ".config/kwinrulesrc"
        ".config/kxkbrc"
        ".config/mimeapps.list"
        ".config/partitionmanagerrc"
        ".config/plasma-localerc"
        ".config/plasma-nm"
        ".config/plasma-org.kde.plasma.desktop-appletsrc"
        ".config/plasmanotifyrc"
        ".config/plasmarc"
        ".config/plasmashellrc"
        ".config/PlasmaUserFeedback"
        ".config/plasmawindowed-appletsrc"
        ".config/plasmawindowedrc"
        ".config/powermanagementprofilesrc"
        ".config/spectaclerc"
        ".config/startkderc"
        ".config/systemsettingsrc"
        ".config/Trolltech.conf"
        ".config/user-dirs.dirs"
        ".config/user-dirs.locale"

        ".local/share/krunnerstaterc"
        ".local/share/user-places.xbel"
        ".local/share/user-places.xbel.bak"
        ".local/share/user-places.xbel.tbcache"
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

  # home.file."/home/neoscode/.config/mimeapps.list".force = lib.mkForce true;
}
