{
  lib,
  pkgs,
  config,
  options,
  inputs,
  ...
}:
with lib; let
  name = "ai";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};

  mempalaceSkill = ./skills/mempalace.md;
  mempalaceCommands = {
    mempalace-help = ./commands/mempalace/help.md;
    mempalace-init = ./commands/mempalace/init.md;
    mempalace-mine = ./commands/mempalace/mine.md;
    mempalace-search = ./commands/mempalace/search.md;
    mempalace-status = ./commands/mempalace/status.md;
  };

  commandDefinitionType = types.submodule {
    options = {
      prompt = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = mdDoc "Prompt text for structured command outputs (for example gemini-cli).";
      };

      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc "Command description for structured command outputs.";
      };

      content = mkOption {
        type = types.nullOr (types.either types.lines types.path);
        default = null;
        description = mdDoc "Raw markdown command content for markdown-based CLIs.";
      };
    };
  };

  commandValueType = types.oneOf [
    types.lines
    types.path
    commandDefinitionType
  ];

  sharedContentType = types.attrsOf (types.either types.lines types.path);
  commandContentType = types.attrsOf commandValueType;
  sharedSkillsType = types.either (types.attrsOf (types.oneOf [types.lines types.path types.str])) types.path;

  hasMcpOption = hasAttrByPath ["programs" "mcp" "servers"] options;
  hasOpencodeOption = hasAttrByPath ["programs" "opencode" "commands"] options;
  hasOpencodeSkillsOption = hasAttrByPath ["programs" "opencode" "skills"] options;
  hasClaudeCodeOption = hasAttrByPath ["programs" "claude-code" "commands"] options;
  hasClaudeCodeSkillsOption = hasAttrByPath ["programs" "claude-code" "skills"] options;
  hasGeminiOption = hasAttrByPath ["programs" "gemini-cli" "commands"] options;
  hasGeminiSkillsOption = hasAttrByPath ["programs" "gemini-cli" "skills"] options;
  hasGithubCopilotCliOption = hasAttrByPath ["programs" "github-copilot-cli" "agents"] options;
  hasGithubCopilotCliSkillsOption = hasAttrByPath ["programs" "github-copilot-cli" "skills"] options;

  effectiveCommands = cfg.commands // optionalAttrs cfg.mempalace.enable mempalaceCommands;
  effectiveSkills =
    if isAttrs cfg.skills
    then cfg.skills // optionalAttrs cfg.mempalace.enable {mempalace = mempalaceSkill;}
    else cfg.skills;

  mkDefaultAttrs = attrs: mapAttrs (_: value: mkDefault value) attrs;
  hasGlobalContext = cfg.context != "";
  hasGlobalSkills = effectiveSkills != {};

  isPathLike = value:
    isPath value
    || (isString value && (hasPrefix builtins.storeDir value || hasPrefix "/" value));

  normalizeCommand = value:
    if isAttrs value
    then value
    else {
      prompt = null;
      description = null;
      content = value;
    };

  normalizedCommands = mapAttrs (_: value: normalizeCommand value) effectiveCommands;

  toPromptString = command:
    if command.prompt != null
    then command.prompt
    else if command.content == null
    then ""
    else if isPathLike command.content
    then builtins.readFile command.content
    else command.content;

  toGeminiCommand = name: command: {
    prompt = toPromptString command;
    description =
      if command.description != null
      then command.description
      else "Run ${name} command.";
  };

  toMarkdownCommand = name: command:
    if command.content != null
    then command.content
    else
      concatStringsSep "" [
        (optionalString (command.description != null) "# ${name}\n\n${command.description}\n\n")
        (toPromptString command)
      ];

  opencodeCommands = mapAttrs toMarkdownCommand normalizedCommands;
  claudeCodeCommands = mapAttrs toMarkdownCommand normalizedCommands;
  geminiCommands = mapAttrs toGeminiCommand normalizedCommands;
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "shared AI tooling");

    mcps = mkOption {
      type = types.attrsOf types.attrs;
      default = {};
      description = mdDoc "MCP servers forwarded to `programs.mcp.servers`.";
      example = literalExpression ''
        {
          context7 = {
            url = "https://mcp.context7.com/mcp";
          };
        }
      '';
    };

    commands = mkOption {
      type = commandContentType;
      default = {};
      description = mdDoc "Global commands forwarded to enabled AI CLI targets.";
    };

    agents = mkOption {
      type = sharedContentType;
      default = {};
      description = mdDoc "Global agents forwarded to supported agent targets.";
    };

    context = mkOption {
      type = types.either types.lines types.path;
      default = "";
      description = mdDoc "Global context forwarded to enabled AI CLI targets.";
    };

    skills = mkOption {
      type = sharedSkillsType;
      default = {};
      description = mdDoc "Global skills forwarded to enabled AI CLI targets.";
    };

    targets = {
      opencode = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc "Forward commands and agents to opencode.";
      };

      claude-code = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc "Forward commands and agents to claude-code.";
      };

      gemini-cli = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc "Forward commands to gemini-cli.";
      };

      github-copilot-cli = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc "Forward agents (and MCP integration) to github copilot cli HM module.";
      };
    };

    mempalace = {
      enable = mkEnableOption (mdDoc "mempalace integration for shared ai tooling");
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = all (command: command.content != null || command.prompt != null) (attrValues normalizedCommands);
          message = "`modules.programs.ai.commands.<name>` must set either `content` or `prompt` when using attribute syntax.";
        }
      ];

      warnings =
        optional (!hasMcpOption && cfg.mcps != {})
        "`modules.programs.ai.mcps` is set, but `programs.mcp` is unavailable in this Home Manager version."
        ++ optional (!hasOpencodeOption && cfg.targets.opencode && (effectiveCommands != {} || cfg.agents != {} || hasGlobalContext || hasGlobalSkills))
        "`modules.programs.ai.targets.opencode` is enabled, but `programs.opencode` is unavailable."
        ++ optional (!hasClaudeCodeOption && cfg.targets.claude-code && (effectiveCommands != {} || cfg.agents != {} || hasGlobalContext || hasGlobalSkills))
        "`modules.programs.ai.targets.claude-code` is enabled, but `programs.claude-code` is unavailable."
        ++ optional (!hasGeminiOption && cfg.targets.gemini-cli && (effectiveCommands != {} || hasGlobalContext || hasGlobalSkills))
        "`modules.programs.ai.targets.gemini-cli` is enabled, but `programs.gemini-cli` is unavailable."
        ++ optional (!hasGithubCopilotCliOption && cfg.targets.github-copilot-cli && (cfg.agents != {} || hasGlobalContext || hasGlobalSkills))
        "`modules.programs.ai.targets.github-copilot-cli` is enabled, but `programs.github-copilot-cli` is unavailable."
        ++ optional (!hasOpencodeSkillsOption && cfg.targets.opencode && hasGlobalSkills)
        "`modules.programs.ai.skills` is set, but `programs.opencode.skills` is unavailable."
        ++ optional (!hasClaudeCodeSkillsOption && cfg.targets.claude-code && hasGlobalSkills)
        "`modules.programs.ai.skills` is set, but `programs.claude-code.skills` is unavailable."
        ++ optional (!hasGeminiSkillsOption && cfg.targets.gemini-cli && hasGlobalSkills)
        "`modules.programs.ai.skills` is set, but `programs.gemini-cli.skills` is unavailable."
        ++ optional (!hasGithubCopilotCliSkillsOption && cfg.targets.github-copilot-cli && hasGlobalSkills)
        "`modules.programs.ai.skills` is set, but `programs.github-copilot-cli.skills` is unavailable."
        ++ optional (cfg.mempalace.enable && !(isAttrs cfg.skills))
        "`modules.programs.ai.mempalace.enable` adds a default mempalace skill only when `modules.programs.ai.skills` is an attribute set.";

      programs.mcp = mkIf (hasMcpOption && cfg.mcps != {}) {
        enable = mkDefault true;
        servers = mkDefaultAttrs cfg.mcps;
      };
    }
    (mkIf (hasOpencodeOption && cfg.targets.opencode) {
      programs.opencode = {
        enableMcpIntegration = true;
        commands = mkDefaultAttrs opencodeCommands;
        agents = mkDefaultAttrs cfg.agents;
        context = mkIf hasGlobalContext (mkDefault cfg.context);
        skills = mkIf (hasGlobalSkills && hasOpencodeSkillsOption) (mkDefault effectiveSkills);
      };
    })
    (mkIf (hasClaudeCodeOption && cfg.targets.claude-code) {
      programs.claude-code = {
        enableMcpIntegration = true;
        commands = mkDefaultAttrs claudeCodeCommands;
        agents = mkDefaultAttrs cfg.agents;
        context = mkIf hasGlobalContext (mkDefault cfg.context);
        skills = mkIf (hasGlobalSkills && hasClaudeCodeSkillsOption) (mkDefault effectiveSkills);
      };
    })
    (mkIf (hasGeminiOption && cfg.targets.gemini-cli) {
      programs.gemini-cli = {
        enableMcpIntegration = true;
        commands = mkDefaultAttrs geminiCommands;
        context = mkIf hasGlobalContext {
          GEMINI = mkDefault cfg.context;
        };
        skills = mkIf (hasGlobalSkills && hasGeminiSkillsOption) (mkDefault effectiveSkills);
      };
    })
    (mkIf (hasGithubCopilotCliOption && cfg.targets.github-copilot-cli) {
      programs.github-copilot-cli = {
        enableMcpIntegration = true;
        agents = mkDefaultAttrs cfg.agents;
        context = mkIf hasGlobalContext (mkDefault cfg.context);
        skills = mkIf (hasGlobalSkills && hasGithubCopilotCliSkillsOption) (mkDefault effectiveSkills);
      };
    })
    (mkIf cfg.mempalace.enable {
      programs.mcp = mkIf hasMcpOption {
        enable = mkDefault true;
        servers.mempalace = mkDefault {
          command = lib.getExe' inputs.packages.packages.${pkgs.system}.python.mempalace "mempalace-mcp";
          args = [];
        };
      };
    })
  ]);
}
