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

        tmux = {
          enable = mkEnableOption (mdDoc "tmux keys for the sidebar and agent jumping");
        };

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
            # One shared tree beside the repo, not upstream's per-repo sibling default.
            worktree_dir = "../.worktrees/{project}";
            # Empty, not absent — the default fast-deletes node_modules on removal.
            pre_remove = [];
            # Without this, first run prompts and tries to write this read-only config.
            nerdfont = true;
            # Upstream's default minus `project`, which repeats the handle instead of naming the project.
            dashboard = {
              worktree_columns = ["number" "worktree" "git" "pr" "mux" "age" "agent"];
              # The repo carries more worktrees than one screen; trade preview for rows.
              preview_size = 25;
            };
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

        programs.tmux.extraConfig = mkIf cfg.tmux.enable (mkAfter ''
          # `t` was tmux's clock-mode; `T` is sesh. `L` duplicated `^`, bound in tmux.conf.
          # Keep `-s`, or the sidebar adds a pane to every window of every session.
          bind-key t run-shell '${getExe cfg.package} sidebar -s'
          bind-key Tab run-shell '${getExe cfg.package} last-agent'
          bind-key L run-shell '${getExe cfg.package} last-done'
        '');
      };
    };
}
