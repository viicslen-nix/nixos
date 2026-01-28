{
  lib,
  config,
  ...
}:
with lib; let
  name = "powerManagement";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    powerManagement.cpuFreqGovernor = "powersave";

    services = {
      power-profiles-daemon.enable = false;

      tlp = {
        enable = true;
        settings = {
          START_CHARGE_THRESH_BAT0 = 75;
          STOP_CHARGE_THRESH_BAT0 = 90;

          CPU_BOOST_ON_AC = 0;
          CPU_BOOST_ON_BAT = 0;
          CPU_HWP_DYN_BOOST_ON_AC = 0;
          CPU_HWP_DYN_BOOST_ON_BAT = 0;
          CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";

          INTEL_GPU_MIN_FREQ_ON_AC = 500;
          INTEL_GPU_MIN_FREQ_ON_BAT = 300;
        };
      };
    };
  };
}
