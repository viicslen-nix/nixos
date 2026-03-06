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
in {
  imports = [
    inputs.worktrunk.homeModules.default
  ];

  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    settings = mkOption {
      type = tomlFormat.type;
      default = {
        list.summary = true;
        worktree-path = "{{ repo_path }}/tree/{{ branch | sanitize }}";
        commit.generation.command = "opencode run -m opencode/minimax-m2.5-free --variant fast";
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

    xdg.configFile."worktrunk/config.toml" = mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "worktrunk-config" cfg.settings;
    };
  };
}
