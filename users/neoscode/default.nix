{
  lib,
  pkgs,
  osConfig,
  homeModules,
  ...
}: let
  user = "neoscode";
in {
  imports = with homeModules.programs; [
    zsh
    tmux
    herdr
    btop
    tmate
    atuin
    ghostty
    ideavim
    nushell
    starship
    worktrunk
    git
    jujutsu
    sesh
  ];

  age = {
    identityPaths = ["${osConfig.users.users.${user}.home}/.ssh/agenix"];

    secrets.intelephense = {
      file = ../../secrets/intelephense/licence.age;
      path = "${osConfig.users.users.${user}.home}/intelephense/licence.txt";
    };

    secrets.avante-anthropic-api-key = {
      file = ../../secrets/avante/anthropic-api-key.age;
    };
  };

  home = {
    username = osConfig.users.users.${user}.name;
    homeDirectory = osConfig.users.users.${user}.home;

    packages = with pkgs; [
      inputs.opencode.oh-my-opencode
      inputs.packages.python.mempalace
    ];

    # ssh refuses to open a control socket if the ControlPath directory is
    # missing, which breaks any host using ControlMaster. See the ControlPath
    # declaration in programs.ssh.settings below.
    file.".ssh/controlmasters/.keep".text = "";

    autostart = [
      {
        package = pkgs._1password-gui;
        args = ["--silent"];
        delay = 5;
      }
    ];

    sessionVariables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
    };
  };

  xdg = {
    configFile = {
      "gh/hosts.yml".source = (pkgs.formats.yaml {}).generate "hosts.yml" {
        "github.com" = {
          user = "viicslen";
          git_protocol = "https";
          users = {
            viicslen = "";
          };
        };
      };
    };
  };

  programs = {
    carapace.enable = true;
    zoxide.enable = true;
    helix.enable = true;

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      extensions = [pkgs.github-copilot-cli];
      settings.prompts = "disabled";
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
      historyWidget.command = "";
    };

    hstr = {
      enable = true;
      enableZshIntegration = true;
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*".ControlPath = "/home/${user}/.ssh/controlmasters/%r@%h:%p";
        "work.neoscode.com".ProxyCommand = "${lib.getExe pkgs.cloudflared} access ssh --hostname %h";
      };
    };
  };

  modules = {
    functionality.defaults = with pkgs; {
      terminal = pkgs.inputs.ghostty.default;
      editor = vscode-fhs;
      fileManager = nautilus;
      browser = vivaldi;
      passwordManager = _1password-gui;
    };
    programs = {
      worktrunk.tmux.enable = true;

      git = {
        user = osConfig.users.users.${user}.description;
        email = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
      jujutsu = {
        userName = osConfig.users.users.${user}.description;
        userEmail = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
      sesh = {
        enableNushellIntegration = true;
        enableTmuxIntegration = true;
      };
    };
  };
}
