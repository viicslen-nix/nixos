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
    modern = mkEnableOption (mdDoc "Enable modern NVIDIA driver");
    prime = mkEnableOption (mdDoc "Enable PRIME offloading");
    specialisation = mkEnableOption (mdDoc "Enable specialisation for NVIDIA sync");
  };

  config = mkIf cfg.enable {
    boot.kernelParams = ["nvidia_drm.fbdev=1"];

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          libGL
          vaapiVdpau
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
      };
    };

    specialisation = mkIf cfg.specialisation {
      nvidia-sync.configuration = {
        system.nixos.tags = ["nvidia-sync"];
        hardware.nvidia = {
          powerManagement.finegrained = lib.mkForce false;

          prime.offload.enable = lib.mkForce false;
          prime.offload.enableOffloadCmd = lib.mkForce false;

          prime.sync.enable = lib.mkForce true;
          dynamicBoost.enable = lib.mkForce true;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      zenith-nvidia
      nvtopPackages.nvidia
    ];

    services.xserver.videoDrivers = ["nvidia"];
  };
}
