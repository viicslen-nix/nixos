{
  flake.modules.nixos.intel = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "intel";
      namespace = "hardware";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
      };

      config = mkIf cfg.enable {
        boot.kernelParams = ["intel_iommu=on"];

        hardware.graphics.extraPackages = with pkgs; [
          intel-media-driver
        ];
      };
    };
}
