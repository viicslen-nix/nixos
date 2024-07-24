{
  inputs,
  pkgs,
  lib,
  ...
}:
with lib; {
  home = {
    file."firefox-gnome-theme" = {
      target = ".mozilla/firefox/default/chrome/firefox-gnome-theme";
      source = pkgs.fetchFromGitHub {
        owner = "rafaelmardojai";
        repo = "firefox-gnome-theme";
        rev = "da947fb21506f26df5f2954df125b83b88666d54";
        sha256 = "sha256-ihOVmsno400zgdgSdRRxKRzmKiydH0Vux7LtSDpCyUI=";
      };
    };
  };

  programs.firefox = {
    enable = mkDefault true;
    profiles.default = {
      name = "Default";
      settings = {
        "accessibility.typeaheadfind.manual" = false;
        "accessibility.typeaheadfind.autostart" = false;

        "browser.uidensity" = 0;
        "browser.tabs.loadInBackground" = true;
        "browser.tabs.loadBookmarksInBackground" = true;
        "browser.theme.dark-private-windows" = false;

        "toolkit.tabbox.switchByScrolling" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        "svg.context-properties.content.enabled" = true;

        "widget.gtk.rounded-bottom-corners.enabled" = true;

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
