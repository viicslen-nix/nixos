{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    microsoft-edge-wayland
    termius
    appflowy
  ];

  programs.ray.enable = true;
  programs.tinkerwell.enable = true;

  programs.ssh.matchBlocks."FmTod" = {
    hostname = "webapps";
    user = "fmtod";
  };

  programs.ssh.matchBlocks."SellDiam" = {
    hostname = "webapps";
    user = "inventory";
  };
}
