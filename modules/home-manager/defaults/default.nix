{
  stateVersion,
  lib,
  ...
}: {
  config = with lib; {
    # Set state version
    home.stateVersion = mkDefault stateVersion;

    # Allow home-manager to manage itself
    programs.home-manager.enable = mkDefault true;

    # Use sd-switch to manage systemd services
    systemd.user.startServices = mkDefault "sd-switch";

    # Configure the package manager
    nixpkgs.config = import ./nixpkgs.nix;
    xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs.nix;
  };
}
