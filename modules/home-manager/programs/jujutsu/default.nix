{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "jujutsu";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    userName = mkOption {
      type = types.str;
      description = "The name of the user to use for jujutsu.";
    };
    userEmail = mkOption {
      type = types.str;
      description = "The email of the user to use for jujutsu.";
    };
    signingKey = mkOption {
      type = types.str;
      description = "The signing key to use for jujutsu.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      jujutsu
      lazyjj
      meld
      mergiraf
    ];

    programs.jujutsu = {
      enable = true;
      settings = {
        git = {
          auto-local-bookmark = true;
          push-new-bookmarks = true;
        };
        user = {
          name = cfg.userName;
          email = cfg.userEmail;
        };
        ui = {
          editor = "nvim";
          diff-editor = "meld-3";
          merge-editor = "meld";
          default-command = ["log"];
        };
        signing = {
          backend = "ssh";
          behavior = "own";
          key = cfg.signingKey;
        };
      };
    };
  };
}
