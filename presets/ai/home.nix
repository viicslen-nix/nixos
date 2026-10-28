{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [inputs.ai.homeManagerModules.default];

  # llm-agents installs the CLI only as `agy`; resolve it from PATH, or the proxy's `agy` launcher is bypassed.
  home.packages = [(pkgs.writeShellScriptBin "antigravity" ''exec agy "$@"'')];

  # The gateway firewall flags backticks/`$(...)` as shell injection in every
  # argument except these keys; the list replaces its built-in defaults (the
  # first 15), so keep them. Only the shell scan is skipped — SQL and
  # path-traversal scans still run on these keys.
  xdg.configFile."mcp-gateway/firewall.env".text = ''
    MCP_GATEWAY_FIREWALL_SKIP_KEYS=description,body,summary,content,message,prompt,comment,comment_body,title,rationale,context,notes,rollback,ac,acceptance_criteria,sql,text,old_string,new_string
  '';

  programs = {
    claude-code = let
      claudeCodeRepo = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-code";
        rev = "53f9910f6ef015ddda6a4b5fceab5dd745af7f4c";
        sha256 = "sha256-ba7eTo6L4Xdb86kS9khFKXOIWWBmlNfUk8W39cSLWeM=";
      };
    in {
      enable = true;
      plugins.ralph-wiggum = "${claudeCodeRepo}/plugins/ralph-wiggum";
    };
    antigravity-cli.enable = true;
    github-copilot-cli.enable = true;
    codex.enable = true;
    pi.coding-agent.enable = true;
  };

  modules.programs = {
    claude-code.mods.readable-output.enable = true;
    opencode = {
      enable = true;
      default = "v2";
    };

    # Not `~`: the gateway runs with HOME set to its state dir.
    ai.integrations.gateway.settings.env_files = ["${config.xdg.configHome}/mcp-gateway/firewall.env"];

    ai.proxy = {
      default = true;
      baseUrl = "https://cliproxyapi.tailb6b9b6.ts.net";
      apiKeyFile = lib.mkDefault "${config.xdg.configHome}/cliproxyapi/api-key";
      models = let
        thinking = api: name: {
          inherit api name;
          reasoning = true;
        };
      in {
        claude-opus-5-5 = thinking "anthropic" "Claude Opus 5.5";
        claude-sonnet-5-5 = thinking "anthropic" "Claude Sonnet 5.5";
        claude-haiku-5-5 = thinking "anthropic" "Claude Haiku 5.5";
        claude-fable-5-1 = thinking "anthropic" "Claude Fable 5.1";
        titan = thinking "anthropic" "Titan (Opus 5.5)";
        vanguard = thinking "anthropic" "Vanguard (Sonnet 5.5)";
        spark = thinking "anthropic" "Spark (Haiku 5.5)";
        "gpt-6.1-sol" = thinking "openai" "GPT-6.1 Sol";
        gpt-6-sol = thinking "openai" "GPT-6 Sol";
        gpt-6-luna = thinking "openai" "GPT-6 Luna";
        "gpt-5.6-sol" = thinking "openai" "GPT-5.6 Sol";
        "gemini-3.8-flash-high" = thinking "gemini" "Gemini 3.8 Flash (High)";
        gemini-pro-agent = thinking "gemini" "Gemini Pro Agent";
      };
      launchers = {
        codex.model = "gpt-6.1-sol";
        copilot.model = "claude-sonnet-5-5";
      };
    };
  };
}
