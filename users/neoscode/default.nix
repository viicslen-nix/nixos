{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}: let
  user = "neoscode";
in {
  age = {
    identityPaths = ["${osConfig.users.users.${user}.home}/.ssh/agenix"];

    secrets.intelephense = {
      file = ../../secrets/intelephense/licence.age;
      path = "${osConfig.users.users.${user}.home}/intelephense/licence.txt";
    };

    secrets.avante-anthropic-api-key = {
      file = ../../secrets/avante/anthropic-api-key.age;
    };
  };

  home = {
    username = osConfig.users.users.${user}.name;
    homeDirectory = osConfig.users.users.${user}.home;

    sessionVariables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
      AVANTE_ANTHROPIC_API_KEY = "$(${pkgs.coreutils}/bin/cat ${config.age.secrets.avante-anthropic-api-key.path})";
    };

    packages = [
      pkgs.vivaldi-snapshot
    ];
  };

  xdg = {
    configFile = {
      "gh/hosts.yml".source = (pkgs.formats.yaml {}).generate "hosts.yml" {
        "github.com" = {
          user = "viicslen";
          git_protocol = "https";
          users = {
            viicslen = "";
          };
        };
      };
    };
  };

  programs = {
    carapace.enable = true;
    zoxide.enable = true;
    btop.enable = true;
    helix.enable = true;

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      extensions = [pkgs.gh-copilot];
      settings.prompts = "disabled";
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };

    hstr = {
      enable = true;
      enableZshIntegration = true;
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*".controlPath = "/home/${user}/.ssh/controlmasters/%r@%h:%p";
        "work.neoscode.com".proxyCommand = "${lib.getExe pkgs.cloudflared} access ssh --hostname %h";
      };
    };

    nushell = {
      extraEnv = let
        # Convert shell variable syntax to nushell interpolation syntax
        # ${VAR_NAME} -> ($env.VAR_NAME)
        secretPath = builtins.replaceStrings ["\${" "}"] ["($env." ")"] config.age.secrets.avante-anthropic-api-key.path;
      in ''
        $env.AVANTE_ANTHROPIC_API_KEY = (open --raw $"${secretPath}");
      '';
    };

    opencode = {
      enable = true;
      settings = {
        autoshare = false;
        provider.anthropic.options.setCacheKey = true;
        model = "anthropic/claude-sonnet-4-5";
        small_model = "anthropic/claude-haiku-4-5";
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
          "opencode-gemini-auth@latest"
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
      '';
    };
  };

  modules = {
    functionality.defaults = with pkgs; {
      terminal = kitty;
      editor = vscode-fhs;
      fileManager = nautilus;
      browser = vivaldi-snapshot;
      passwordManager = _1password-gui;
    };
    programs = {
      zsh.enable = true;
      k9s.enable = true;
      tmux.enable = true;
      aider.enable = true;
      tmate.enable = true;
      atuin.enable = true;
      ideavim.enable = true;
      nushell.enable = true;
      starship.enable = true;
      git = {
        enable = true;
        user = osConfig.users.users.${user}.description;
        email = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
      jujutsu = {
        enable = true;
        userName = osConfig.users.users.${user}.description;
        userEmail = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
      sesh = {
        enable = true;
        enableNushellIntegration = true;
        enableTmuxIntegration = true;
      };
    };
  };
}
