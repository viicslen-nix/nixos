{
  lib,
  homeModules,
  ...
}: {
  imports = with homeModules; [
    programs.kitty
  ];

  dconf.settings = {
    "org/gnome/shell/extensions/arcmenu" = {
      menu-button-border-color = lib.hm.gvariant.mkTuple [true "transparent"];
      menu-button-border-radius = lib.hm.gvariant.mkTuple [true 10];
    };
  };
}
