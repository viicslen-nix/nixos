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
  # not command+args, and calls the remote transport `http_url`.
  toBackend = server:
    removeAttrs server ["command" "args" "url"]
    // (
      if (server.url or null) != null
      then {http_url = server.url;}
      else {command = escapeShellArgs ([server.command] ++ (server.args or []));}
    );

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

    # Also placed where the CLI auto-discovers it, so `mcp-gateway list|doctor`
    # in a shell sees the same config the service runs.
    xdg.configFile."mcp-gateway/gateway.yaml".source = configFile;

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
