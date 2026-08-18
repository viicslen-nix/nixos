# Global Claude Code preferences — the whole of `~/.claude/settings.json` apart
# from the hooks, which each integrating module contributes for itself
# (`modules.programs.ai` for mempalace/superset, `modules.programs.herdr`).
#
# Claude Code rewrites this file itself (`/config`, model switches), as do the
# mempalace/ponytail/superset hook installers. Once home-manager owns it those
# runtime edits land in `settings.json.backup` and are dropped on the next
# activation, so change settings here rather than in the TUI.
{
  flake.modules.homeManager.claude-code = {
    lib,
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
        programs.claude-code.settings =
          recursiveUpdate {
            model = "opus[1m]";
            effortLevel = "high";

            permissions.defaultMode = "auto";

            statusLine = {
              type = "command";
              command = "npx -y ccstatusline@latest";
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
