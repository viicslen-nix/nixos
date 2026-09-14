{
  flake.modules.homeManager.workmux = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "workmux";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      yamlFormat = pkgs.formats.yaml {};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        package = mkOption {
          type = types.package;
          default = pkgs.inputs.llm-agents.workmux;
          defaultText = literalExpression "pkgs.inputs.llm-agents.workmux";
          description = mdDoc "The workmux package to use; it is not in nixpkgs.";
        };

        settings = mkOption {
          inherit (yamlFormat) type;
          default = {
            # Both keys, or the session is `wm-<name>` and workmux stops adopting worktrunk's.
            mode = "session";
            window_prefix = "";
            # Spelled out rather than left to the default, which upstream may move.
            worktree_dir = "../{project}__worktrees";
            # Empty, not absent — the default fast-deletes node_modules on removal.
            pre_remove = [];
            # Without this, first run prompts and tries to write this read-only config.
            nerdfont = true;
          };
          description = ''
            Configuration written to {file}`$XDG_CONFIG_HOME/workmux/config.yaml`.
            See <https://workmux.raine.dev> for the available options.
          '';
          example = literalExpression ''
            {
              mode = "window";
              merge_strategy = "rebase";
            }
          '';
        };
      };

      config = mkIf cfg.enable {
        home.packages = [cfg.package];

        xdg.configFile."workmux/config.yaml" = mkIf (cfg.settings != {}) {
          source = yamlFormat.generate "workmux-config" cfg.settings;
        };
      };
    };
}
