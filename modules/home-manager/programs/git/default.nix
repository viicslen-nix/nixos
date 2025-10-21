{
  lib,
  config,
  ...
}:
with lib; let
  name = "git";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    user = mkOption {
      type = types.nullOr types.str;
      description = "The user name to use for git commits.";
    };
    email = mkOption {
      type = types.nullOr types.str;
      description = "The email address to use for git commits.";
    };
    signingKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The GPG key to use for signing commits.";
    };
    defaultBranch = mkOption {
      type = types.str;
      default = "main";
      description = "The default branch name to use when initializing new repositories.";
    };
  };

  config.programs = mkIf cfg.enable {
    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = mkIf (cfg.user != null) cfg.user;
          email = mkIf (cfg.email != null) cfg.email;
          signingkey = mkIf (cfg.signingKey != null) cfg.signingKey;
        };
        alias = {
          st = "status";
          su = "submodule foreach 'git checkout main && git pull'";
          nah = ''!f(){ git reset --hard; git clean -df; if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then git rebase --abort; fi; }; f'';
          forget = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D";
          forgetlist = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}'";
          uncommit = "reset --soft HEAD~0";
        };
        init.defaultBranch = cfg.defaultBranch;
        push.autoSetupRemote = true;
        pull.rebase = true;

        submodule.recurse = true;
      };
    };
  };
}
