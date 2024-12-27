{
  lib,
  config,
  ...
}:
with lib; let
  name = "kanata";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config =mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kanata
    ];

    services.kanata = {
      enable = true;
      keyboards = {
        "default".config = ''
          (defsrc
            caps
            lsft
          )

          (deflayermap (default-layer)
            ;; tap caps lock as caps lock, hold caps lock as left control
            caps lsft
            lsft lctl
          )
        '';
      };
    };
  };
}
