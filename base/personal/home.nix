{pkgs, ...}: let
  nix2yaml = pkgs.formats.yaml {};
in {
  home.autostart = with pkgs; [
    mullvad-vpn
    discord
  ];

  programs.git = {
    enable = true;
    userName = "Victor R";
    userEmail = "39545521+viicslen@users.noreply.github.com";
    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
      web.browser = "microsoft-edge";
    };
  };

  xdg.configFile."gh/hosts.yml".source = nix2yaml.generate "hosts.yml" {
    "github.com" = {
      user = "viicslen";
      git_protocol = "https";
      users = {
        viicslen = "";
      };
    };
  };
}
