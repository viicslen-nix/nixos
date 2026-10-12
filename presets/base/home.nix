{
  lib,
  config,
  inputs,
  osConfig,
  ...
}: {
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.ai.homeManagerModules.opencode
    inputs.ai.homeManagerModules.opencode1
    inputs.zed.homeManagerModules.default
  ];

  config = {
    home = {
      # Set state version
      stateVersion = lib.mkDefault osConfig.system.stateVersion;

      # Add local bin to PATH
      sessionPath = ["$HOME/.local/bin"];
    };

    # xresources predates preferXdgDirectories and needs saying twice.
    xresources.path = "${config.xdg.configHome}/xresources";

    # Allow home-manager to manage itself
    programs.home-manager.enable = lib.mkDefault true;

    # Use sd-switch to manage systemd services
    systemd.user.startServices = lib.mkDefault "sd-switch";

    # Configure the package manager
    xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs.nix;

    # Disable manual
    manual.manpages.enable = lib.mkDefault false;
    programs.man.enable = lib.mkDefault false;
  };
}
