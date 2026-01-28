{
  lib,
  pkgs,
  config,
  options,
  ...
}:
with lib; let
  homeManagerLoaded = builtins.hasAttr "home-manager" options;
  name = "virtual-machines";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "virtual-machines");

    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to add to the libvirtd group";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true;

      users.users.${cfg.user}.extraGroups = ["libvirtd"];

      environment.systemPackages = with pkgs; [
        qemu
        quickemu
        quickgui
      ];
    }
    (mkIf homeManagerLoaded {
      home-manager.users.${cfg.user} = {
        dconf.settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = ["qemu:///system"];
            uris = ["qemu:///system"];
          };
        };
      };
    })
  ]);
}
