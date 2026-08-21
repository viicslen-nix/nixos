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

      # Nushell has no `eval`, and `source` needs a path known at parse time,
      # so the hook cannot be piped in the way the posix shells do it. Generate
      # it once at build time and source the store path.
      initFile =
        pkgs.runCommand "iris-init.nu" {}
        "${getExe cfg.package} init nu > $out";

      atuinEnabled = config.programs.atuin.enable;

      # IRIS is a PTY wrapper holding the terminal in raw mode, so it sees every
      # keystroke *before* nushell does. Whatever it binds is taken outright
      # from reedline, and therefore from atuin and carapace, which are only
      # reedline keybindings and a reedline completer. There is no sharing a
      # key; the only question is who gets it.
      #
      # iris is the thing you touch on every keystroke, so it keeps its stock
      # bindings -- tab, shift+tab, up, down, right, ctrl+r. atuin gives up
      # ctrl+r (below) and keeps the up arrow, which still reaches it: iris
      # declines navigation on an empty prompt and passes the key through.
      # The split ends up clean:
      #
      #   empty prompt + up   -> atuin search
      #   menu open + up/down -> iris moves the selection
      #   ctrl+r              -> iris spec/history mode toggle
      #   tab                 -> iris accepts (carapace loses its menu)

      defaultSettings = {
        core = {
          version = 1;
          shell = "nu";
          # Not "last". That restores the previous mode from
          # ~/.local/share/iris/state.toml, and landing in history mode makes
          # every up/down overwrite the command line instead of moving a
          # selection -- correct for history mode, baffling as a default you
          # did not ask for. ctrl+r still toggles within a session.
          mode = "spec";
          expand-alias = true;
          # 1 = read atuin's history.db instead of nushell's history.txt.
          # iris' default path is $XDG_DATA_HOME/atuin/history.db, which is
          # where the atuin module already puts it, so no atuin-db-path needed.
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

        # Stock upstream bindings, spelled out so a future upstream default
        # change cannot silently move them.
        #
        # Tab costs carapace its completion menu -- carapace still answers
        # nushell's completer for anything iris does not intercept, but the
        # menu no longer opens on Tab. To hand Tab back and run iris as a
        # passive overlay, set `settings.keybindings.select = "none"` and
        # accept with the right arrow instead.
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

        # iris owns ctrl+r for its mode toggle. atuin keeps the up arrow: iris
        # declines navigation on an empty prompt and passes the key through,
        # so the familiar empty-prompt-up still opens atuin.
        programs.atuin.flags = mkIf atuinEnabled ["--disable-ctrl-r"];

        # mkAfter: the hook reads $env.config.hooks, so it has to run after the
        # integrations that populate them (direnv, atuin) rather than before.
        programs.nushell.extraConfig = mkAfter ''
          source ${initFile}
        '';
      };
    };
}
