{
  flake.modules.homeManager.iris = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "iris";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      tomlFormat = pkgs.formats.toml {};

      # Nushell has no `eval` and `source` needs a parse-time path; don't pipe this in.
      initFile =
        pkgs.runCommand "iris-init.nu" {}
        "${getExe cfg.package} init nu > $out";

      atuinEnabled = config.programs.atuin.enable;

      defaultSettings = {
        core = {
          version = 1;
          shell = "nu";
          # Not "last": it restores history mode, where up/down overwrite the command line.
          mode = "spec";
          expand-alias = true;
          # 1 = read atuin's history.db instead of nushell's history.txt.
          atuin-history =
            if atuinEnabled
            then 1
            else 0;
        };

        ui = {
          style = "modern";
          ghost-text = true;
          max-height = 12;
        };

        # Stock upstream bindings, spelled out so an upstream change cannot move them.
        keybindings = {
          select = "tab";
          toggle-menu = "shift+tab";
          toggle-mode = "ctrl+r";
          navigate-up = "up";
          navigate-down = "down";
          navigate-right = "right";
        };

        # Nix owns the binary; the self-updater would try to overwrite the
        # store path and `iris update` shells out to `curl … | sh`.
        updater = {
          check-on-startup = false;
          auto-update = 0;
        };
      };
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        package = mkPackageOption pkgs.local "iris" {};

        settings = mkOption {
          inherit (tomlFormat) type;
          default = {};
          description = ''
            Extra configuration merged over the defaults and written to
            {file}`$XDG_CONFIG_HOME/iris/config.toml`. Values here win.
            See <https://github.com/versenilvis/iris> for the options.
          '';
          example = literalExpression ''
            {
              # hand Tab back to carapace; accept with the right arrow instead
              keybindings.select = "none";
              ui.nerd-fonts = false;
            }
          '';
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = config.programs.nushell.enable;
            message = ''
              modules.programs.iris expects nushell: it configures
              core.shell = "nu" and sources its hook from nushell's config.
              Enable modules.programs.nushell, or set
              modules.programs.iris.settings.core.shell to a shell you use.
            '';
          }
        ];

        home.packages = [cfg.package];

        xdg.configFile."iris/config.toml".source =
          tomlFormat.generate "iris-config"
          (recursiveUpdate defaultSettings cfg.settings);

        # iris owns ctrl+r for its mode toggle, so atuin must give it up.
        programs.atuin.flags = mkIf atuinEnabled ["--disable-ctrl-r"];

        # mkAfter: the hook reads $env.config.hooks, so it has to run after the
        # integrations that populate them (direnv, atuin) rather than before.
        programs.nushell.extraConfig = mkAfter ''
          source ${initFile}
        '';
      };
    };
}
