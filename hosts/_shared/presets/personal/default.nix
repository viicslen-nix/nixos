{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  config = {
    # Optimization: Prevent systemd from waiting for network online
    # (Optional but recommended for faster boot with VPNs)
    systemd.network.wait-online.enable = false;
    boot.initrd.systemd.network.wait-online.enable = false;

    environment.systemPackages = with pkgs; [
      nix-alien
      nix-init
      graphviz
      asciinema
      yazi
      ytmdesktop
      android-tools
      scrcpy
      qtscrcpy
      ferdium
      inputs.nixvim.default
      inputs.packages.scripts.git-carve-submodule
    ];

    programs = {
      localsend.enable = mkDefault true;
    };

    modules = {
      core.theming.enable = true;
      programs.qmk.enable = mkDefault true;
      containers.homarr.enable = mkDefault true;
    };
  };
}
