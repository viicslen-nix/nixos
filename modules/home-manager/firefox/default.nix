{
  pkgs,
  lib,
  ...
}:
with lib; {
  home = {
    sessionVariables = {
      BROWSER = "firefox";
    };

    file."firefox-gnome-theme" = {
      target = ".mozilla/firefox/default/chrome/firefox-gnome-theme";
      source = pkgs.fetchFromGitHub {
        owner = "rafaelmardojai";
        repo = "firefox-gnome-theme";
        rev = "master";
        sha256 = "sha256-EACja6V2lNh67Xvmhr0eEM/VeqM7OlTTm/81LhRbsBE=";
      };
    };
  };

  programs.firefox = {
    enable = true;
    profiles.default = {
      name = "Default";
      settings = {
        "accessibility.typeaheadfind.manual" = false;
        "accessibility.typeaheadfind.autostart" = false;
        "browser.tabs.loadInBackground" = true;
        "browser.tabs.loadBookmarksInBackground" = true;
        "toolkit.tabbox.switchByScrolling" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "svg.context-properties.content.enabled" = true;

        "gnomeTheme.hideSingleTab" = true;
        "gnomeTheme.normalWidthTabs" = false;
        "gnomeTheme.tabsAsHeaderbar" = false;
        "gnomeTheme.bookmarksToolbarUnderTabs" = true;
      };
      userChrome = ''
        @import "firefox-gnome-theme/userChrome.css";
      '';
      userContent = ''
        @import "firefox-gnome-theme/userContent.css";
      '';
    };
    nativeMessagingHosts = [
      pkgs.browserpass
    ];
  };

  xdg = {
    enable = mkDefault true;

    desktopEntries.firefox-direct = {
      name = "Firefox (Direct)";
      icon = "${pkgs.firefox}/share/icons/hicolor/256x256/apps/firefox.png";
      genericName = "Web Browser";
      exec = "${pkgs.mullvad}/bin/mullvad-exclude ${pkgs.firefox}/bin/firefox";
      terminal = false;
      categories = ["Application" "Network" "WebBrowser"];
      mimeType = ["text/html" "text/xml"];
      settings = {
        StartupWMClass = "firefox";
      };
    };
  };
}
