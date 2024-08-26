# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    # Apps and Keybindings
    "org/gnome/shell" = {
      favorite-apps = [ "org.gnome.Nautilus.desktop" "microsoft-edge.desktop" "phpstorm.desktop" "kitty.desktop" "slack.desktop" ];
    };

    "org/gnome/shell/keybindings" = {
      screenshot = [ "<Shift><Alt><Super>s" ];
      screenshot-window = [ "<Control><Alt><Super>s" ];
      show-screen-recording-ui = [ "<Shift><Super>r" ];
      show-screenshot-ui = [ "<Shift><Super>s" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" ];
      screenreader = [];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Shift><Control>space";
      command = "1password --quick-access";
      name = "1Password";
    };
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = "microsoft-edge.desktop";
    "x-scheme-handler/https" = "microsoft-edge.desktop";
  };
}
