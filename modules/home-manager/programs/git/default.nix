{
  lib,
  config,
  pkgs,
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
    jetbrainIntegration = {
      enable = mkEnableOption "Whether to use phpstorm for diff and merge";
      cmdExe = mkOption {
        type = types.str;
        default = "phpstorm";
        description = "The path to the JetBrains command line launcher executable.";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
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
        pull.rebase = true;
        push = {
          autoSetupRemote = true;
          # recurseSubmodules = "on-demand";
        };

        # submodule.recurse = true;
      } // optionalAttrs cfg.jetbrainIntegration.enable {
        diff.tool = "jetbrains";
        merge.tool = "jetbrains";
        difftool = {
          prompt = false;
          jetbrains = {
            cmd = ''${cfg.jetbrainIntegration.cmdExe} diff $(cd $(dirname "$LOCAL") && pwd)/$(basename "$LOCAL") $(cd $(dirname "$REMOTE") && pwd)/$(basename "$REMOTE")'';
            trustExitCode = true;
          };
        };
        mergetool.jetbrains = {
          cmd = ''${cfg.jetbrainIntegration.cmdExe} merge $(cd $(dirname "$LOCAL") && pwd)/$(basename "$LOCAL") $(cd $(dirname "$REMOTE") && pwd)/$(basename "$REMOTE") $(cd $(dirname "$BASE") && pwd)/$(basename "$BASE") $(cd $(dirname "$MERGED") && pwd)/$(basename "$MERGED")'';
          trustExitCode = true;
        };
      };
    };
  };
}
