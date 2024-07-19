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
    vivaldi
    vivaldi-ffmpeg-codecs

    via
    keymapviz
    qmk
    qmk_hid
    qmk-udev-rules
  ];
}
