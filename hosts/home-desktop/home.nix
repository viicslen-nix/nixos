{pkgs, ...}: {
  home.packages = with pkgs; [
    rpi-imager
    orca-slicer
    platformio
  ];

  services.tailscale-systray = {
    enable = true;
    theme = "dark:nobg";
  };
}
