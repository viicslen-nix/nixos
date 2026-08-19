{
  flake.modules.homeManager.t3code = {
    lib,
    pkgs,
    config,
    inputs,
    ...
  }:
    with lib;
    with inputs.self.lib; let
      name = "t3code";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      # nixpkgs builds t3code from source, which drops two things upstream's
      # own release builds carry: the public T3 Connect config (without it the
      # `t3 connect` subcommand is hidden outright) and a bundled relay client
      # (without it `t3 connect link` downloads its own cloudflared into ~/.t3).
      # All four are plain env lookups that win over the build-time fallbacks.
      # symlinkJoin folds its `postBuild` into `buildCommand`, so append there.
      wrapped = pkgs.unstable.t3code.overrideAttrs (old: {
        buildCommand =
          old.buildCommand
          + ''
            for program in "$out/bin"/*; do
              wrapProgram "$program" \
                --set-default T3CODE_RELAY_URL "https://relay.t3.codes" \
                --set-default T3CODE_CLERK_PUBLISHABLE_KEY "pk_live_Y2xlcmsudDMuY29kZXMk" \
                --set-default T3CODE_CLERK_CLI_OAUTH_CLIENT_ID "hzxSgY2cH10sDU2r" \
                --set-default T3CODE_CLOUDFLARED_PATH "${getExe cfg.cloudflaredPackage}"
            done
          '';
      });
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        package = mkOption {
          type = types.package;
          default = wrapped;
          defaultText = literalExpression "pkgs.unstable.t3code (wrapped with the T3 Connect public config)";
          description = mdDoc "The t3code package providing the `t3` CLI and the desktop app.";
        };

        cloudflaredPackage = mkOption {
          type = types.package;
          default = pkgs.cloudflared;
          defaultText = literalExpression "pkgs.cloudflared";
          description = mdDoc ''
            Relay client T3 Connect tunnels through. Pinning it here keeps
            `t3 connect link` from fetching its own copy at runtime.
          '';
        };

        serve = {
          enable = mkEnabledOption (mdDoc "the T3 Code server as a systemd user service");

          host = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = mdDoc ''
              Interface to bind. Leave on loopback when reaching the machine
              through T3 Connect — the relay client dials out from here.
            '';
          };

          port = mkOption {
            type = types.port;
            default = 3773;
            description = mdDoc "Port for the HTTP/WebSocket server.";
          };

          workingDirectory = mkOption {
            type = types.str;
            default = config.home.homeDirectory;
            description = mdDoc "Working directory for provider sessions.";
          };

          tailscaleServe = mkEnableOption (mdDoc "exposing the server over HTTPS on the Tailnet");
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          home.packages = [cfg.package];

          # Upstream's own `t3 service install` writes a unit that runs a
          # self-updating launcher, which npm-installs new versions over
          # itself — declare the server directly instead. Starting it is also
          # what provisions a `t3 connect link` that is still pending.
          systemd.user.services.${name} = mkIf cfg.serve.enable {
            Unit = {
              Description = "T3 Code server";
              After = ["network-online.target"];
              Wants = ["network-online.target"];
            };

            Service = {
              Type = "simple";
              WorkingDirectory = cfg.serve.workingDirectory;
              ExecStart = concatStringsSep " " ([
                  (getExe' cfg.package "t3")
                  "serve"
                  "--no-browser"
                  "--host"
                  cfg.serve.host
                  "--port"
                  (toString cfg.serve.port)
                ]
                ++ optional cfg.serve.tailscaleServe "--tailscale-serve");
              KillMode = "mixed";
              Restart = "always";
              RestartSec = 5;
            };

            Install.WantedBy = ["default.target"];
          };
        }

        # `t3 connect login`/`link` persist their authorization here, alongside
        # the project database — losing it means re-authorizing every boot.
        (persistence.mkPersistence config {
          directories = [".t3"];
        })
      ]);
    };
}
