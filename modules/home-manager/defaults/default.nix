{
  stateVersion,
  lib,
  ...
}: {
  config = with lib; {
    home = {
      # Set state version
      stateVersion = mkDefault stateVersion;

      # Add local bin to PATH
      sessionPath = ["$HOME/.local/bin"];
    };

    # Allow home-manager to manage itself
    programs.home-manager.enable = mkDefault true;

    # Use sd-switch to manage systemd services
    systemd.user.startServices = mkDefault "sd-switch";

    # Configure the package manager
    xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs.nix;

    # Disable manual
    manual.manpages.enable = mkDefault false;
    programs.man.enable = mkDefault false;
  };
}
