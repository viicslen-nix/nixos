{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: let
  nix2yaml = pkgs.formats.yaml { };
in {
  home.packages = with pkgs; [
    orca-slicer
    betterbird
  ];

  home.autostart = with pkgs; [
    mullvad-vpn
  ];

  programs.git = {
    enable = true;
    userName = "Victor R";
    userEmail = "39545521+viicslen@users.noreply.github.com";
  };

  xdg.configFile."gh/hosts.yml".source = (nix2yaml.generate "hosts.yml" {
    "github.com" = {
      user = "viicslen";
      git_protocol = "https";
      users = {
        viicslen = "";
      };
    };
  });
}
