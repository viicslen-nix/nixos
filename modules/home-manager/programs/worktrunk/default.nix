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

      # `=name` is an exact tmux target; a bare name prefix-matches `repo@feat` to `repo@feat-x`.
      postSwitchScript = pkgs.writeShellScript "worktrunk-post-switch" ''
        S=$1
        W=$2

        tmux has-session -t "=$S" 2>/dev/null || tmux new-session -d -s "$S" -c "$W"

        if [ -n "''${TMUX:-}" ]; then
          tmux switch-client -t "=$S"
        else
          tmux attach-session -t "=$S"
        fi
      '';

      # Never kill the session `wt` itself runs in — that takes the removal down mid-hook.
      killSessionScript = pkgs.writeShellScript "worktrunk-kill-session" ''
        [ "$(tmux display -p '#S' 2>/dev/null)" = "$1" ] || tmux kill-session -t "=$1" 2>/dev/null || true
      '';

      dashboard = pkgs.writeShellApplication {
        name = "wt-dashboard";
        runtimeInputs = with pkgs; [config.programs.worktrunk.package fzf jq git tmux coreutils gnugrep xdg-utils];
        text = builtins.readFile ./dashboard.sh;
      };
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
            worktree-path = "../.worktrees/{{ repo }}/{{ branch | sanitize }}";
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
          # The session template is repeated in `dashboard.sh`'s jq; change all three together.
          tmuxSettings = optionalAttrs cfg.tmux.enable {
            pre-remove.tmux = "${killSessionScript} '{{ repo }}@{{ branch | sanitize }}'";
            # `{% raw %}` survives the alias engine's pass so `wt switch` renders the inner template.
            aliases.tmux = "wt switch {{ args }} --no-cd --execute='${postSwitchScript} \"{% raw %}{{ repo }}@{{ branch | sanitize }}{% endraw %}\" \"{% raw %}{{ worktree_path }}{% endraw %}\"'";
          };
          mergedSettings = recursiveUpdate cfg.settings tmuxSettings;
        in
          mkIf (cfg.settings != {}) {
            source = tomlFormat.generate "worktrunk-config" mergedSettings;
          };

        home.packages = mkIf cfg.tmux.enable [dashboard];

        programs.tmux.extraConfig = mkIf cfg.tmux.enable (mkAfter ''
          bind-key W display-popup -E -d "#{pane_current_path}" -w 90% -h 85% -T " worktrees " '${getExe dashboard}'
        '');
      };
    };
}
