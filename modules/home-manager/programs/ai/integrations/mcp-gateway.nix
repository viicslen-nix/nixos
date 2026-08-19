{
  lib,
  cfg,
  pkgs,
  config,
  mcps,
}:
with lib; let
  gcfg = cfg.gateway;
  yaml = pkgs.formats.yaml {};

  # mcp-gateway takes a single shell-ish `command` string (split with shlex),
  # not command+args, and calls the remote transport `http_url`. Remote
  # endpoints default to Streamable HTTP unless the URL names the legacy `/sse`
  # transport — with `streamable_http` off the gateway opens an SSE GET
  # handshake instead, which every `/mcp` endpoint rejects, and the backend
  # silently never connects. The computed attrs come first so anything set on
  # the server itself still wins.
  toBackend = server:
    (
      if (server.url or null) != null
      then {
        http_url = server.url;
        streamable_http = !hasSuffix "/sse" server.url;
      }
      else {command = escapeShellArgs ([server.command] ++ (server.args or []));}
    )
    // removeAttrs server ["command" "args" "url"];

  # `meta_mcp.warm_start` is deliberately left unset: an empty list means
  # *every* backend is warm-started, which is what a browser-OAuth backend
  # needs (its consent handshake runs at startup instead of stalling the first
  # tool call). Naming backends there would narrow warm-start to just those.
  settings =
    recursiveUpdate {
      server.port = gcfg.port;
      backends = mapAttrs (_: toBackend) mcps;
    }
    gcfg.settings;

  configFile = yaml.generate "gateway.yaml" settings;
in {
  # The single MCP entry every AI CLI gets when the gateway is on; everything
  # else is reached through its meta tools.
  servers.gateway.url = "http://127.0.0.1:${toString gcfg.port}/mcp";

  options = {
    gateway = {
      enable = mkEnableOption (mdDoc "routing every `modules.programs.ai.mcps` server through mcp-gateway");

      package = mkOption {
        type = types.package;
        default = pkgs.mcp-gateway;
        defaultText = literalExpression "pkgs.mcp-gateway";
        description = mdDoc "The mcp-gateway package to run.";
      };

      port = mkOption {
        type = types.port;
        default = 39400;
        description = mdDoc "Port the gateway listens on (loopback only).";
      };

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = mdDoc "Extra `gateway.yaml` settings, merged over the generated `server`/`backends` sections.";
        example = literalExpression ''
          {
            capabilities = {
              enabled = true;
              directories = ["./capabilities"];
            };
          }
        '';
      };
    };
  };

  assertions = [
    {
      assertion =
        !gcfg.enable
        || all (server: all isString (attrValues (server.env or {}))) (attrValues mcps);
      message = "`modules.programs.ai.gateway.enable` cannot route an MCP server that uses `env.<name>.file`; mcp-gateway only accepts literal environment values.";
    }
  ];

  config = mkIf gcfg.enable {
    home.packages = [gcfg.package];

    xdg.configFile."mcp-gateway/gateway.yaml".source = configFile;

    # `list`/`get`/`add`/`remove`/`doctor` each carry their own `-c`, defaulting
    # to a cwd-relative `gateway.yaml`; only `serve` falls back to
    # `~/.config/mcp-gateway/gateway.yaml`. This env var is the one knob that
    # points all of them at the generated config from any directory.
    home.sessionVariables.MCP_GATEWAY_CONFIG = "${config.xdg.configHome}/mcp-gateway/gateway.yaml";

    systemd.user.services.mcp-gateway = {
      Unit = {
        Description = "MCP Gateway";
        After = ["network.target"];
      };

      Service = {
        ExecStart = "${getExe gcfg.package} --config ${configFile} serve";
        Restart = "on-failure";
        RestartSec = "5s";
        # stdio backends shell out to npx and friends.
        Environment = "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/run/wrappers/bin";
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
