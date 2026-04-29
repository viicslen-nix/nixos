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
          create = "wt switch --create {{ args }}";
          delete = "wt remove --force -D  {{ args }}";
          workspace = "wt switch --base=@ --create  {{ args }}";
          since-main = "git log --oneline {{ default_branch }}..HEAD";
          move-changes = ''
            if git diff --quiet HEAD && test -z "$(git ls-files --others --exclude-standard)"; then
              wt switch --create {{ to }} --execute="{{ args }}"
            else
              git stash push --include-untracked --quiet
              wt switch --create {{ to }} --execute="git stash pop --index; {{ args }}"
            fi
          '';
          copy-changes = ''
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
        switch.cd = false;
        post-switch.tmux = "${postSwitchScript} \"{{ repo }}@{{ branch | sanitize }}\" {{ worktree_path }}";
        pre-remove.tmux = "tmux kill-session -t {{ repo }}@{{ branch | sanitize }} 2>/dev/null || true";
      };
      mergedSettings = cfg.settings // tmuxSettings;
    in
      mkIf (cfg.settings != {}) {
        source = tomlFormat.generate "worktrunk-config" mergedSettings;
      };
  };
}
