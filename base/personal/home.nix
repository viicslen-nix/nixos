{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  home.packages = with pkgs; [
    thorium
    floorp

    vial
    keymapviz
    qmk
    qmk_hid
    qmk-udev-rules
  ];
}
