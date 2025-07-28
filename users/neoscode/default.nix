{
  pkgs,
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
  };

  home = {
    username = osConfig.users.users.${user}.name;
    homeDirectory = osConfig.users.users.${user}.home;

    sessionVariables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
    };
  };

  programs = {
    carapace.enable = true;
    zoxide.enable = true;
    k9s.enable = true;
    btop.enable = true;
    helix.enable = true;

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      extensions = [pkgs.gh-copilot];
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
      controlPath = "/home/${user}/.ssh/controlmasters/%r@%h:%p";
    };

    git = {
      enable = true;
      delta.enable = true;
      userName = osConfig.users.users.${user}.description;
      userEmail = "39545521+viicslen@users.noreply.github.com";
      aliases = {
        st = "status";
        su = "submodule foreach 'git checkout main && git pull'";
        nah = ''!f(){ git reset --hard; git clean -df; if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then git rebase --abort; fi; }; f'';
        forget = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D";
        forgetlist = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}'";
        uncommit = "reset --soft HEAD~0";
      };
      extraConfig = {
        pull.rebase = true;
        init.defaultBranch = "main";
        user.signingkey = builtins.readFile ./ssh/git-signing-key.pub;

        submodule.recurse = true;
        # status.submoduleSummary = true;

        push = {
          autoSetupRemote = true;
          # recurseSubmodules = "on-demand";
        };
      };
    };
  };

  modules = {
    programs = {
      zsh.enable = true;
      tmux.enable = true;
      aider.enable = true;
      tmate.enable = true;
      atuin.enable = true;
      ideavim.enable = true;
      nushell.enable = true;
      starship.enable = true;
      sesh = {
        enable = true;
        enableNushellIntegration = true;
        enableTmuxIntegration = true;
      };
      jujutsu = {
        enable = true;
        userName = osConfig.users.users.${user}.description;
        userEmail = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
    };
  };
}
