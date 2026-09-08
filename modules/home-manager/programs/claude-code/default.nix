{
  flake.modules.homeManager.claude-code = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "claude-code";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      mkMarketplace = repo: {
        source = {
          source = "github";
          inherit repo;
        };
      };
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc "global Claude Code settings");

        marketplaces = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = mdDoc "Plugin marketplaces to register, as `<name> = \"<owner>/<repo>\"`.";
          example = literalExpression ''{ponytail = "DietrichGebert/ponytail";}'';
        };

        plugins = mkOption {
          type = types.attrsOf types.bool;
          default = {};
          description = mdDoc "Plugins to enable or disable, keyed by `<plugin>@<marketplace>`.";
          example = literalExpression ''{"ponytail@ponytail" = true;}'';
        };

        settings = mkOption {
          type = types.attrs;
          default = {};
          description = mdDoc "Extra `settings.json` entries, merged over the defaults below.";
        };
      };

      config = mkIf cfg.enable {
        # Don't drop `force`: the next activation then aborts on a stale settings.json.backup.
        home.file."${config.home.homeDirectory}/.claude/settings.json".force = true;

        programs.claude-code.settings =
          recursiveUpdate {
            model = "opus[1m]";
            effortLevel = "high";

            autoCompactWindow = 500000;

            permissions.defaultMode = "auto";

            statusLine = {
              type = "command";
              # Keep this a store path; `npx -y ccstatusline@latest` re-resolves every render.
              command = getExe pkgs.local.ccstatusline;
              padding = 0;
              refreshInterval = 10;
            };

            # `programs.claude-code.marketplaces` only emits `source = "directory"`
            # entries, so github ones are written straight through.
            extraKnownMarketplaces = mapAttrs (_: mkMarketplace) cfg.marketplaces;
            enabledPlugins = cfg.plugins;

            workflowKeywordTriggerEnabled = true;
            syntaxHighlightingDisabled = false;
            alwaysThinkingEnabled = true;
            autoMemoryEnabled = false;
            tui = "fullscreen";
            skipDangerousModePermissionPrompt = true;
            theme = "auto";
            editorMode = "vim";
            verbose = false;
            remoteControlAtStartup = false;
            inputNeededNotifEnabled = true;
            agentPushNotifEnabled = true;
          }
          cfg.settings;
      };
    };
}
