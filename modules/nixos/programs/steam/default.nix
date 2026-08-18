{
  flake.modules.nixos.steam = {
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
        enable = mkEnableOption (mdDoc name) // {default = true;};
      };

      config = mkIf cfg.enable (mkMerge [
        {
          programs.steam.enable = true;
        }
        (persistence.mkHmPersistence {
          inherit config options;
          users = attrNames users;
          directories = [".steam"];
          share = ["Steam"];
        })
      ]);
    };
}
