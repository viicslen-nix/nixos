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

      # A source build of t3code has T3 Connect compiled out: `scripts/lib/
      # public-config.ts` feeds the repo's `.env` into both vite builds, so
      # without it the CLI hides the `connect` subcommand and the web client
      # bakes in empty Clerk/relay literals, which is what strips the T3
      # Connect block from Settings › Connections. Upstream's documented fix
      # for source builds is to copy `.env.example` — public identifiers, not
      # secrets — into place, so take that verbatim rather than restating the
      # values here. Costs a full rebuild of the pnpm/electron tree.
      unwrapped = pkgs.unstable.t3code.unwrapped.overrideAttrs (old: {
        postPatch =
          old.postPatch
          + ''
            cp .env.example .env
          '';
      });

      # The relay client T3 Connect tunnels through is the one piece not
      # covered by `.env`: upstream downloads its own cloudflared on first
      # `t3 connect link`. Point it at the Nix one instead.
      # symlinkJoin folds its `postBuild` into `buildCommand`, so append there.
      wrapped = (pkgs.unstable.t3code.override {t3code-unwrapped = unwrapped;}).overrideAttrs (old: {
        buildCommand =
          old.buildCommand
          + ''
            for program in "$out/bin"/*; do
              wrapProgram "$program" \
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
          defaultText = literalExpression "pkgs.unstable.t3code (rebuilt with the T3 Connect public config)";
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
