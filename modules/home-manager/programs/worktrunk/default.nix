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

  postCreateScript = pkgs.writeShellScript "worktrunk-post-create" ''
    S=$1
    W=$2
    tmux new-session -d -s "$S" -c "$W"
    echo "✓ Session '$S' — attach with: tmux attach -t $S"
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
        worktree-path = "{{ repo_path }}/tree/{{ branch | sanitize }}";
        commit.generation.command = "${commitScript}";
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/worktrunk/config.toml`.
        See <https://github.com/max-sixty/worktrunk> for the available options.
      '';
      example = literalExpression ''
        {
          worktree-path = "../{{ repo }}.{{ branch | sanitize }}";
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
        switch.no-cd = true;
        post-create.tmux = "${postCreateScript} {{ branch | sanitize }} {{ worktree_path }}";
        pre-remove.tmux = "tmux kill-session -t {{ branch | sanitize }} 2>/dev/null || true";
      };
      mergedSettings = cfg.settings // tmuxSettings;
    in
      mkIf (cfg.settings != {}) {
        source = tomlFormat.generate "worktrunk-config" mergedSettings;
      };
  };
}
