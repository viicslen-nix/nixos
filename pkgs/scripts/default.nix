{pkgs, ...}: rec {
  system-update = pkgs.callPackage ./system-update.nix {};
  system-upgrade = pkgs.callPackage ./system-upgrade.nix {};
}
