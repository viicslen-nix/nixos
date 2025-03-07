{
  lib,
  config,
  ...
}:
with lib; let
  name = "steam";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        localNetworkGameTransfers.openFirewall = true;
        gamescopeSession.enable = true;
        # package = pkgs.steam.override {
        #   withJava = true;
        #   withPrimus = true;
        #   extraPkgs = pkgs: [ bumblebee glxinfo ];
        # };
      };

      gamescope = {
        enable = true;
        capSysNice = true;
      };

      # java.enable = true;
    };
  };
}
