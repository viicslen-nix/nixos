{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  user,
  ...
}: {
  home-manager.users.${user} = import ./home.nix;

  environment.systemPackages = with pkgs; [
    insomnia
    nix-alien
    nix-init
    qemu
    quickemu
    quickgui
    openlens
    skypeforlinux
    stable.redisinsight
    kdePackages.kcachegrind
    graphviz
    handbrake
    sesh

    # Devices
    solaar
    openrgb-with-all-plugins

    # GUI Apps
    libreoffice-fresh
    tangram
    endeavour
    drawing
    kooha

    # Development
    vscode
    obsidian
    qownnotes
    warp-terminal
    mysql-workbench
    drawio
    siege
  ];

  features = {
    onePassword = {
      enable = true;
      inherit user;
    };

    mullvad = {
      enable = true;
      enableExludeIPs = true;
      excludedIPs = [
        # Nivoda
        "172.66.43.155"
        "172.66.40.101"
        "104.26.4.176"
        "172.67.68.183"
        "104.26.5.176"
        "108.139.10.82"
        "108.139.10.70"
        "108.139.10.74"
        "108.139.10.67"
      ];
    };
  };
}
