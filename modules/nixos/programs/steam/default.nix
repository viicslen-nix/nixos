{
  lib,
  config,
  options,
  users,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "steam";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs = {
        steam = {
          enable = true;
          localNetworkGameTransfers.openFirewall = true;
          gamescopeSession.enable = true;
        };

        gamescope = {
          enable = true;
          capSysNice = true;
        };
      };
    }
    (mkNixosPersistence {
      inherit config options;
      users = attrNames users;
      directories = [".steam"];
      share = ["Steam"];
    })
  ]);
}
