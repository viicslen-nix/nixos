{
  lib,
  pkgs,
  ...
}: {
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

  modules = {
    programs = {
      ray.enable = true;
      kitty.enable = true;
      tinkerwell.enable = true;
      lan-mouse = {
        enable = true;
        autostart = true;
      };
    };
  };

  stylix.targets.kde.enable = false;
}
