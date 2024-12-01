{
  lib,
  user,
  description,
  password,
  stateVersion,
  ...
}: {
  users.users.${user} = {
    isNormalUser = true;
    inherit description;
    initialPassword = lib.mkIf (password == "") user;
    hashedPassword = lib.mkIf (password != "") password;
    extraGroups = ["networkmanager" user];
  };

  home-manager.users.${user} = {
    home = {
      username = user;
      homeDirectory = "/home/${user}";
      inherit stateVersion;
    };

    features.zsh.enable = true;
    features.tmux.enable = true;

    programs = {
      ssh.enable = true;

      git = {
        enable = true;
        delta.enable = true;
      };

      gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      fzf = {
        enable = true;
        enableZshIntegration = true;
        tmux.enableShellIntegration = true;
      };

      zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = ["--cmd cd"];
      };

      hstr = {
        enable = true;
        enableZshIntegration = true;
      };
    };
  };
}
