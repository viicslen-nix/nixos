{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}: let
  user = "neoscode";
in {
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

    sessionVariables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
      AVANTE_ANTHROPIC_API_KEY = "$(${pkgs.coreutils}/bin/cat ${config.age.secrets.avante-anthropic-api-key.path})";
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
    btop.enable = true;
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
    };

    hstr = {
      enable = true;
      enableZshIntegration = true;
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*".controlPath = "/home/${user}/.ssh/controlmasters/%r@%h:%p";
        "work.neoscode.com".proxyCommand = "${lib.getExe pkgs.cloudflared} access ssh --hostname %h";
      };
    };

    nushell = {
      extraEnv = let
        # Convert shell variable syntax to nushell interpolation syntax
        # ${VAR_NAME} -> ($env.VAR_NAME)
        secretPath = builtins.replaceStrings ["\${" "}"] ["($env." ")"] config.age.secrets.avante-anthropic-api-key.path;
      in ''
        $env.AVANTE_ANTHROPIC_API_KEY = (open --raw $"${secretPath}");
      '';
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
      zsh.enable = true;
      k9s.enable = true;
      tmux.enable = true;
      aider.enable = true;
      tmate.enable = true;
      atuin.enable = true;
      ghostty.enable = true;
      ideavim.enable = true;
      nushell.enable = true;
      starship.enable = true;
      opencode.enable = true;
      git = {
        enable = true;
        user = osConfig.users.users.${user}.description;
        email = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
      jujutsu = {
        enable = true;
        userName = osConfig.users.users.${user}.description;
        userEmail = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
      sesh = {
        enable = true;
        enableNushellIntegration = true;
        enableTmuxIntegration = true;
      };
    };
  };
}
