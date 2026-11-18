{
  flake.modules.homeManager.netbird = {
    lib,
    pkgs,
    config,
    osConfig,
    ...
  }:
    with lib; let
      name = "netbird";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
      };

      config = mkIf cfg.enable {
        home.autostart = [
          {
            package = pkgs.netbird-ui;
            # netbird-ui ignores NB_* variables, so it must be pointed at the NixOS daemon's socket.
            args = ["--daemon-addr=${osConfig.services.netbird.clients.default.environment.NB_DAEMON_ADDR}"];
          }
        ];
      };
    };
}
