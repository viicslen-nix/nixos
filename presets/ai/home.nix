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

    ai.integrations.gateway.settings = {
      # Not `~`: the gateway runs with HOME set to its state dir.
      env_files = ["${config.xdg.configHome}/mcp-gateway/firewall.env"];
      code_mode.enabled = true;
      auth = {
        enabled = true;
        # Not a literal: gateway.yaml is in the world-readable store.
        bearer_token = "auto";
        single_user = true;
        # Keep `/mcp` public, or every harness needs the token.
        public_paths = ["/health" "/mcp"];
      };
    };

    ai.proxy = {
      default = true;
      baseUrl = lib.mkDefault "https://cliproxyapi.tailb6b9b6.ts.net";
      apiKeyFile = lib.mkDefault "${config.xdg.configHome}/cliproxyapi/api-key";
      models = let
        thinking = api: name: {
          inherit api name;
          reasoning = true;
        };
      in {
        # Fallback aliases: the catalog names them after whichever model answers, so pin api and name.
        titan = thinking "anthropic" "Titan (Opus/Sol)";
        vanguard = thinking "anthropic" "Vanguard (Sonnet/Terra)";
        spark = thinking "anthropic" "Spark (Haiku/Luna)";
      };
      launchers = {
        codex.model = "gpt-sol";
        claude.model = "claude-opus";
      };
    };
  };
}
