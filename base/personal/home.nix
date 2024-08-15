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

  programs.git = {
    enable = true;
    userName = "Victor R";
    userEmail = "39545521+viicslen@users.noreply.github.com";
  };
}
