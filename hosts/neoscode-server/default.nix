{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  user,
  ...
}: {
  imports = [
    ./hardware.nix
    ../../base/nixos
    ../../base/server
  ];

  users.users.${user}.openssh.authorizedKeys.keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCxl3OFptBRpUYBM7lKIAquaQaDSi8XYp4fjXuJUWLeS9iwd7pPoqyWg/AvFTuG5mSX5I91rim4Mp+tSkVRzbxRBcqNHJ9EBBgMi+E3R+Rp7uZFZYQpS7ySdzdfRQtjM4i5ciwjX02RZqIzCcIANB8ttcJKauBHx1/5LVZyqBY517y0MBhdSd3hmcJcFN3T9ppuGYzmnEF8tIXtKmXGMLUYqOSlyhpBDvSthQGKZtAtI7TujGNLWOYedH/f6LkxZTWKMiNlfO3tZoRJcfUqxHzZmvRJYrfh+QrkChAl9S7r3IfVhm1mCngCDsbOqbVDLHNV3IrHdU8xgJUH5t9uQREj5M73k8FTd8pnxV6KmVc1rePiDueDRnvs6L9L0PFyKUPMTC6uZiSkdUH6IM7qLKAcMCmd53TuUVF20RoH4+1hN2LMZLhhhTRu/sOWinz0T4aeDWpKf2JOhoFrx+Hwo6qCFv3mbonVKiEzI1Sd9VHGcrh0pxWdkhOMjd1KU8carvEEu/M/NZTGub0NJhPU7qw9oNJaiQa5xQ4Ka6DTx0DJe4KuIyBs2u1AEc1KrViPD36/1lo/IagYNEN7Sl8ozohEp0J/irmhA4HvMN/kIdUZH3Y1edo2c0EN4BehSnM001Y2rCk8V/DjYkugnCSmdz5xuVAqimebsHadscj/v0jOw== neoscode@laptop"];
  programs.zsh.shellAliases.takeout = "composer global exec -- takeout";

  features = {
    network.hostName = "neoscode-server";

    theming.enable = true;
    sound.enable = false;

    docker = {
      enable = true;
      inherit user;
      allowTcpPorts = [
        # Traefik
        80
        443
        8080

        # PHPStorm Xdebug
        9003

        # Portainer
        9443

        # MySQL
        3306

        # Ray
        23517
      ];
    };
  };
}
