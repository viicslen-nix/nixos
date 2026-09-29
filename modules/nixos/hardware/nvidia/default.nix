{
  flake.modules.nixos.nvidia = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "nvidia";
      namespace = "hardware";

      cfg = config.modules.${namespace}.${name};

      # `features` must restate the package wrapper's own: only the last --enable-features counts.
      withArgs = pkg: {
        features,
        extraFlags ? [],
      }:
        pkg.override {
          commandLineArgs = concatStringsSep " " (extraFlags ++ ["--enable-features=${concatStringsSep "," (features ++ cfg.chromiumFeatures)}"]);
        };
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
        modern = mkEnableOption (mdDoc "Enable modern NVIDIA power management");
        prime = mkEnableOption (mdDoc "Enable PRIME offloading");
        latest = mkEnableOption (mdDoc "Use the latest NVIDIA drivers");

        chromiumFeatures = mkOption {
          type = types.listOf types.str;
          readOnly = true;
          default = ["VaapiOnNvidiaGPUs" "VaapiIgnoreDriverChecks" "AcceleratedVideoDecodeLinuxGL"];
          description = mdDoc "Chromium features that enable VA-API video decode on NVIDIA, for browsers wrapped outside this module.";
        };
      };

      config = mkIf cfg.enable {
        boot.kernelParams = ["nvidia_drm.fbdev=1"];

        nixpkgs.overlays = [
          (_: prev: {
            # --use-angle=vulkan is what lets WebGPU find the GPU; Brave's bundled Vulkan loader cannot take it.
            chromium = withArgs prev.chromium {
              features = ["WaylandWindowDecorations"];
              extraFlags = ["--use-angle=vulkan"];
            };
            google-chrome = withArgs prev.google-chrome {
              features = ["WaylandWindowDecorations"];
              extraFlags = ["--use-angle=vulkan"];
            };
            brave = withArgs prev.brave {
              features = ["AcceleratedVideoEncoder" "WaylandWindowDecorations"];
            };
          })
        ];

        # Firefox's VA-API decode cannot reach the NVIDIA driver from inside the RDD sandbox.
        environment.sessionVariables.MOZ_DISABLE_RDD_SANDBOX = "1";

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
            nvidiaSettings = true;
            modesetting.enable = true;
            dynamicBoost.enable = mkIf cfg.modern true;
            powerManagement.enable = mkIf cfg.modern true;
            powerManagement.finegrained = mkIf (cfg.modern && cfg.prime) true;
            prime.offload.enable = mkIf (cfg.modern && cfg.prime) true;
            package = mkDefault config.boot.kernelPackages.nvidiaPackages.latest;
          };
        };

        environment.systemPackages = with pkgs; [
          zenith-nvidia
          nvtopPackages.nvidia
        ];

        services.xserver.videoDrivers = ["nvidia"];
      };
    };
}
