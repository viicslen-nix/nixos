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
    floorp

    via
    keymapviz
    qmk
    qmk_hid
    qmk-udev-rules
  ];
}
