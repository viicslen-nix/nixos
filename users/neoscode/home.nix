{
  pkgs,
  ...
}: let
  user = "neoscode";
  name = "Victor R";
in {
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    # packages = import ./packages.nix {inherit pkgs;};

    sessionVariables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
    };
  };

  programs = {
    carapace.enable = true;
    thefuck.enable = true;
    zoxide.enable = true;
    k9s.enable = true;
    btop.enable = true;

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      extensions = [pkgs.gh-copilot];
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
      controlPath = "/home/${user}/.ssh/controlmasters/%r@%h:%p";
      matchBlocks = {
        "FmTod" = {
          hostname = "webapps";
          user = "fmtod";
        };

        "SellDiam" = {
          hostname = "webapps";
          user = "inventory";
        };

        "DOS" = {
          hostname = "storesites";
          user = "dostov";
        };

        "BLVD" = {
          hostname = "storesites";
          user = "REDACTED";
        };

        "EXB" = {
          hostname = "storesites";
          user = "REDACTED";
        };

        "DTC" = {
          hostname = "storesites";
          user = "REDACTED";
        };

        "NFC" = {
          hostname = "storesites";
          user = "REDACTED";
        };

        "TJD" = {
          hostname = "storesites";
          user = "REDACTED";
        };

        "47DD" = {
          hostname = "storesites";
          user = "REDACTED";
        };

        "PELA" = {
          hostname = "storesites";
          user = "REDACTED";
        };
      };
    };

    git = {
      enable = true;
      delta.enable = true;
      userName = name;
      userEmail = "39545521+viicslen@users.noreply.github.com";
      aliases = {
        nah = ''!f(){ git reset --hard; git clean -df; if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then git rebase --abort; fi; }; f'';
        forget = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D";
        forgetlist = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}'";
        uncommit = "reset --soft HEAD~0";
      };
      extraConfig = {
        pull.rebase = true;
        init.defaultBranch = "main";
        web.browser = "microsoft-edge";
        user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJk8lwwP7GnxZMgpx+C30i/Lw912BBoFccz4gjek8lCX";
      };
    };

    nvchad = {
      enable = false;
      backup = false;
      extraPackages = with pkgs; [
        nixd
        python3
        php83
        php83Packages.composer
        docker-compose-language-service
        dockerfile-language-server-nodejs
        nodePackages.bash-language-server
        stable.nodePackages.volar
      ];
    };
  };

  modules = {
    programs = {
      zsh.enable = true;
      ray.enable = true;
      tmux.enable = true;
      aider.enable = true;
      tmate.enable = true;
      kitty.enable = true;
      atuin.enable = true;
      ghostty.enable = true;
      nushell.enable = true;
      starship.enable = true;
      tinkerwell.enable = true;
      nvf.enable = true;
      sesh = {
        enable = true;
        enableNushellIntegration = true;
        enableTmuxIntegration = true;
      };
    };
  };
}
