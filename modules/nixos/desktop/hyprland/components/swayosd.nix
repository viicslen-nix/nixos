{pkgs, ...}: {
  home.packages = [
    pkgs.swayosd
  ];

  services.swayosd = {
    enable = true;
  };
}
