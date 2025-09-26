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
      matchBlocks."*".controlPath = "/home/${user}/.ssh/controlmasters/%r@%h:%p";
    };
  };

  modules = {
    functionality.defaults = {
      browser = pkgs.microsoft-edge;
    };
    programs = {
      zsh.enable = true;
      k9s.enable = true;
      tmux.enable = true;
      aider.enable = true;
      tmate.enable = true;
      atuin.enable = true;
      ideavim.enable = true;
      nushell.enable = true;
      starship.enable = true;
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
