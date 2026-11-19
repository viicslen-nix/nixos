{pkgs, ...}: {
  home.packages = with pkgs; [
    rpi-imager
    orca-slicer
    platformio
  ];

  modules.programs.t3code.serve.tailscaleServe = true;

  services.tailscale-systray = {
    enable = true;
    theme = "dark:nobg";
  };
}
