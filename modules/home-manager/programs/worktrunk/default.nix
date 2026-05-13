{
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

  tmuxWorktreePickerScript = pkgs.writeShellScript "worktrunk-tmux-worktree-picker" ''
    set -eu

    GIT='${lib.getExe pkgs.git}'
    TV='${lib.getExe pkgs.television}'
    WT='${lib.getExe config.programs.worktrunk.package}'

    repo_root=$($GIT rev-parse --show-toplevel 2>/dev/null || true)
    if [ -z "$repo_root" ]; then
      printf 'Not inside a git repository.\n' >&2
      exit 1
    fi

    current_branch=$($GIT branch --show-current 2>/dev/null || true)
    selection=$($GIT -C "$repo_root" worktree list --porcelain \
      | awk -v repo="$(basename "$repo_root")" '
          $1 == "worktree" {
            path = substr($0, 10)
            branch = "detached"
            next
          }

          $1 == "branch" {
            branch = $2
            sub("^refs/heads/", "", branch)
            printf "%s@%s\t%s\n", repo, branch, path
            next
          }

          $1 == "detached" {
            printf "%s@detached\t%s\n", repo, path
          }
        ' \
      | $TV \
      | tr -d '\n')

    if [ -z "$selection" ]; then
      exit 0
    fi

    selection_path="''${selection#*$'\t'}"

    target_branch=$($GIT -C "$selection_path" branch --show-current 2>/dev/null || true)

    if [ -z "$target_branch" ] || [ "$target_branch" = "$current_branch" ]; then
      exit 0
    fi

    $WT tmux "$target_branch"
  '';

  postSwitchScript = pkgs.writeShellScript "worktrunk-post-switch" ''
    S=$1
    W=$2

    if ! tmux has-session -t "$S" 2>/dev/null; then
      tmux new-session -d -s "$S" -c "$W"
    fi

    if [ -n "$TMUX" ]; then
      tmux switch-client -t "$S"
    else
      tmux attach-session -t "$S"
    fi
  '';
in {
  imports = [
    inputs.worktrunk.homeModules.default
  ];

  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    tmux = {
      enable = mkEnableOption (mdDoc "tmux session per worktree");
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = {
        list.summary = false;
        merge.squash = false;
        commit.generation.command = "${commitScript}";
        worktree-path = "../{{ repo }}@{{ branch | sanitize }}";
        aliases = {
          create = "wt switch --no-cd --create {{ args }}";
          delete = "wt remove --force -D  {{ args }}";
          workspace = "wt switch --base=@ --create  {{ args }}";
          since-main = "git log --oneline {{ default_branch }}..HEAD";
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
        pre-remove.tmux = "tmux kill-session -t {{ repo }}@{{ branch | sanitize }} 2>/dev/null || true";
        aliases.tmux = "wt switch {{ args }} --no-cd --execute='${postSwitchScript} \"{% raw %}{{ repo }}@{{ branch | sanitize }}{% endraw %}\" {% raw %}{{ worktree_path }}{% endraw %}'";
      };
      mergedSettings = recursiveUpdate cfg.settings tmuxSettings;
    in
      mkIf (cfg.settings != {}) {
        source = tomlFormat.generate "worktrunk-config" mergedSettings;
      };

    programs.tmux.extraConfig = mkIf cfg.tmux.enable (mkAfter ''
      bind-key W new-window -n worktrees -c "#{pane_current_path}" '${tmuxWorktreePickerScript}'
    '');
  };
}
