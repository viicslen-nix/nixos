{
  lib,
  config,
  options,
  users,
  inputs,
  pkgs,
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

  imports = [
    inputs.jovian.nixosModules.default
  ];

  config = mkIf cfg.enable (mkMerge [
    {
      programs = {
        steam = {
          enable = true;
          gamescopeSession.enable = true;
          localNetworkGameTransfers.openFirewall = true;
        };

        gamemode.enable = true;
        gamescope.enable = true;
      };

      environment = {
        systemPackages = with pkgs; [
          mangohud
          lutris
          bottles
          heroic
          protonup-ng
        ];
        sessionVariables = {
          STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
        };
      };

      jovian = {
        steam.enable = true;
        decky-loader.enable = true;
      };
    }
    (persistence.mkHmPersistence {
      inherit config options;
      users = attrNames users;
      directories = [".steam"];
      share = ["Steam"];
    })
  ]);
}
