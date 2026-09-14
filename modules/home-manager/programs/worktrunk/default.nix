{
  flake.modules.homeManager.worktrunk = {
    lib,
    pkgs,
    config,
    inputs,
    ...
  }:
    with lib; let
      name = "worktrunk";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      tomlFormat = pkgs.formats.toml {};

      commitScript = pkgs.writeShellScript "worktrunk-commit" ''
        f=$(mktemp)
        printf '\n\n' > "$f"
        sed 's/^/# /' >> "$f"
        ''${EDITOR:-vi} "$f" < /dev/tty > /dev/tty
        grep -v '^#' "$f"
      '';

      workmux = getExe config.modules.${namespace}.workmux.package;
    in {
      imports = [
        inputs.worktrunk.homeModules.default
      ];

      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        tmux = {
          enable = mkEnableOption (mdDoc "tmux session per worktree");
        };

        settings = mkOption {
          inherit (tomlFormat) type;
          default = {
            merge.squash = false;
            commit.generation.command = "${commitScript}";
            # Keep in step with `modules.programs.workmux.settings.worktree_dir`.
            worktree-path = "../worktrees/{{ repo }}/{{ branch | sanitize }}";
            list = {
              summary = false;
              json-schema = 2;
            };
            aliases = {
              create = "wt switch --no-cd --create {{ args }}";
              delete = "wt remove --force -D  {{ args }}";
              workspace = "wt switch --base=@ --create  {{ args }}";
              since-main = "git log --oneline {{ default_branch }}..HEAD";
              prune = ''
                for branch in $(wt list --format=json --no-progressive | ${getExe pkgs.jq} -r '.items[] | select(.display.state == "integrated") | .branch'); do
                  wt remove {{ args }} "$branch" || wt remove --no-hooks {{ args }} "$branch"
                done
              '';
              mv = ''
                if git diff --quiet HEAD && test -z "$(git ls-files --others --exclude-standard)"; then
                  wt switch --create {{ to }} --execute="{{ args }}"
                else
                  git stash push --include-untracked --quiet
                  wt switch --create {{ to }} --execute="git stash pop --index; {{ args }}"
                fi
              '';
              cp = ''
                if git diff --quiet HEAD && test -z "$(git ls-files --others --exclude-standard)"; then
                  wt switch --create {{ to }} --execute="{{ args }}"
                else
                  git stash push --include-untracked --quiet
                  git stash apply --index --quiet
                  wt switch --create {{ to }} --execute="git stash pop --index; {{ args }}"
                fi
              '';
            };
            projects."github.com/FmTod/mylisterhub-main-app" = {
              pre-start.dirnev = "direnv allow";
            };
          };
          description = ''
            Configuration written to {file}`$XDG_CONFIG_HOME/worktrunk/config.toml`.
            See <https://github.com/max-sixty/worktrunk> for the available options.
          '';
          example = literalExpression ''
            {
              worktree-path = "../{{ repo }}@{{ branch | sanitize }}";
              commit.generation.command = "llm -m claude-haiku-4.5";
            }
          '';
        };
      };

      config = mkIf cfg.enable {
        programs.worktrunk = {
          enable = true;
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          enableNushellIntegration = true;
        };

        xdg.configFile."worktrunk/config.toml" = let
          tmuxSettings = optionalAttrs cfg.tmux.enable {
            pre-remove.tmux = "${workmux} close || true";
            # `{{ branch }}`, not the sanitized dir name — only a branch match finds the primary worktree.
            aliases.tmux = "wt switch {{ args }} --no-cd --execute='${workmux} open \"{% raw %}{{ branch }}{% endraw %}\"'";
          };
          mergedSettings = recursiveUpdate cfg.settings tmuxSettings;
        in
          mkIf (cfg.settings != {}) {
            source = tomlFormat.generate "worktrunk-config" mergedSettings;
          };

        programs.tmux.extraConfig = mkIf cfg.tmux.enable (mkAfter ''
          bind-key W new-window -n worktrees -c "#{pane_current_path}" '${workmux} dashboard -t worktrees'
        '');
      };
    };
}
