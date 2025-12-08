{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "nvidia";
  namespace = "hardware";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    modern = mkEnableOption (mdDoc "Enable modern NVIDIA power management");
    prime = mkEnableOption (mdDoc "Enable PRIME offloading");
  };

  config = mkIf cfg.enable {
    boot.kernelParams = ["nvidia_drm.fbdev=1"];

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          libGL
          libva-vdpau-driver
          libvdpau-va-gl
          nvidia-vaapi-driver
        ];
      };

      nvidia = {
        open = true;
        modesetting.enable = true;
        dynamicBoost.enable = mkIf cfg.modern true;
        powerManagement.enable = mkIf cfg.modern true;
        powerManagement.finegrained = mkIf (cfg.modern && cfg.prime) true;
        prime.offload.enable = mkIf (cfg.modern && cfg.prime) true;

        nvidiaSettings = true;
      };
    };

    environment.systemPackages = with pkgs; [
      zenith-nvidia
      nvtopPackages.nvidia
    ];

    services.xserver.videoDrivers = ["nvidia"];
  };
}
