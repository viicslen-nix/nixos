{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "mullvad";
  namespace = "programs";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name}.splitTunneling = mkOption {
    type = types.listOf types.package;
    default = [];
    description = ''
      List of packages to create a desktop entry with split tunneling.
    '';
  };

  config = {
    home.file = builtins.listToAttrs (map
      (pkg: {
        name = ".config/applications/${pkg.pname}-split-tunneling.desktop";
        value =
          if pkg ? desktopItem
          then {
            # Application has a desktopItem entry.
            # Assume that it was made with makeDesktopEntry, which exposes a
            # text attribute with the contents of the .desktop file
            text = pkg.desktopItem.text;
          }
          else {
            # Application does *not* have a desktopItem entry. Try to find a
            # matching .desktop name in /share/apaplications
            source = pkg + "/share/applications/${pkg.pname}.desktop";
          };
      })
      cfg);
  };
}
