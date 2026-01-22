{
  lib,
  config,
  ...
}:
with lib; let
  name = "opencode";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config.programs.opencode = mkIf cfg.enable {
    enable = true;
    enableMcpIntegration = true;
    agents = {
      ask = ./agents/ask.md;
      debug = ./agents/debug.md;
      review = ./agents/review.md;
      security = ./agents/security.md;
      documentation = ./agents/documentation.md;
    };
    settings = {
      autoshare = false;
      provider = {
        anthropic.options.setCacheKey = true;
        google = {
          models = {
            antigravity-gemini-3-pro = {
              name = "Gemini 3 Pro (Antigravity)";
              limit = {
                context = 1048576;
                output = 65535;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
              variants = {
                low = {
                  thinkingLevel = "low";
                };
                high = {
                  thinkingLevel = "high";
                };
              };
            };
            antigravity-gemini-3-flash = {
              name = "Gemini 3 Flash (Antigravity)";
              limit = {
                context = 1048576;
                output = 65536;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
              variants = {
                minimal = {
                  thinkingLevel = "minimal";
                };
                low = {
                  thinkingLevel = "low";
                };
                medium = {
                  thinkingLevel = "medium";
                };
                high = {
                  thinkingLevel = "high";
                };
              };
            };
            antigravity-claude-sonnet-4-5 = {
              name = "Claude Sonnet 4.5 (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
            };
            antigravity-claude-sonnet-4-5-thinking = {
              name = "Claude Sonnet 4.5 Thinking (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
              variants = {
                low = {
                  thinkingConfig = {
                    thinkingBudget = 8192;
                  };
                };
                max = {
                  thinkingConfig = {
                    thinkingBudget = 32768;
                  };
                };
              };
            };
            antigravity-claude-opus-4-5-thinking = {
              name = "Claude Opus 4.5 Thinking (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
              variants = {
                low = {
                  thinkingConfig = {
                    thinkingBudget = 8192;
                  };
                };
                max = {
                  thinkingConfig = {
                    thinkingBudget = 32768;
                  };
                };
              };
            };
            gemini-2_5-flash = {
              name = "Gemini 2.5 Flash (Gemini CLI)";
              limit = {
                context = 1048576;
                output = 65536;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
            };
            gemini-2_5-pro = {
              name = "Gemini 2.5 Pro (Gemini CLI)";
              limit = {
                context = 1048576;
                output = 65536;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
            };
            gemini-3-flash-preview = {
              name = "Gemini 3 Flash Preview (Gemini CLI)";
              limit = {
                context = 1048576;
                output = 65536;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
            };
            gemini-3-pro-preview = {
              name = "Gemini 3 Pro Preview (Gemini CLI)";
              limit = {
                context = 1048576;
                output = 65535;
              };
              modalities = {
                input = ["text" "image" "pdf"];
                output = ["text"];
              };
            };
          };
        };
      };
      model = "google/antigravity-claude-sonnet-4-5-thinking";
      small_model = "google/antigravity-gemini-3-flash";
      watcher.ignore = [
        "**/node_modules/**"
        "**/.git/**"
        "**/.hg/**"
        "**/.svn/**"
        "**/.DS_Store"
        "**/dist/**"
        "**/build/**"
        "**/.next/**"
        "**/out/**"
        "**/vendor/**"
      ];
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
        gh_grep = {
          type = "remote";
          url = "https://mcp.grep.app";
        };
        github = {
          type = "remote";
          url = "https://api.githubcopilot.com/mcp";
        };
      };
      plugin = [
        "opencode-pty@latest"
        "opencode-antigravity-auth@latest"
        "@tarquinen/opencode-dcp@latest"
        "opencode-websearch-cited@latest"
        "@mohak34/opencode-notifier@latest"
        "@zenobius/opencode-skillful@latest"
        "@nick-vi/opencode-type-inject@latest"
      ];
    };
    rules = ''
      ## External File Loading

      CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

      Instructions:

      - Do NOT preemptively load all references - use lazy loading based on actual need
      - When loaded, treat content as mandatory instructions that override defaults
      - Follow references recursively when needed

      ## Tools

      - When you need to search docs, use `context7` tools.
      - If you are unsure how to do something, use `gh_grep` to search code examples from GitHub.
      - When you need to ask questions to the user, use the `question` tool.
    '';
  };
}
