{
  pkgs,
  user,
  ...
}: {
  home-manager.users.${user} = import ./home.nix;

  environment.systemPackages = with pkgs; [
    insomnia
    nix-alien
    nix-init
    lens
    skypeforlinux
    kdePackages.kcachegrind
    graphviz
    sesh
    asciinema
    waveterm
    discord

    # Devices
    solaar
    openrgb-with-all-plugins

    # GUI Apps
    tangram
    endeavour
    drawing
    kooha

    # Development
    vscode
    obsidian
    qownnotes
    mysql-workbench
    drawio

    # Browsers
    pkgs.inputs.zen-browser.default
  ];

  features = {
    qmk.enable = true;

    onePassword = {
      enable = true;
      inherit user;
      gitSignCommits = true;
      gitSignKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJk8lwwP7GnxZMgpx+C30i/Lw912BBoFccz4gjek8lCX";
      allowedCustomBrowsers = [".zen-wrapped"];
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
