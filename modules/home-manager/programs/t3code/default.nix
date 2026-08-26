{
  flake.modules.homeManager.t3code = {
    lib,
    pkgs,
    config,
    osConfig,
    inputs,
    ...
  }:
    with lib;
    with inputs.self.lib; let
      name = "t3code";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      # `cfg.package` is the *stock* t3code; both fixes below are applied here,
      # so pointing the option at another packaging of it (nixpkgs, or
      # numtide/llm-agents.nix, which has the same two gaps) still gets them.
      #
      # 1. A source build bakes in no cloud config: `scripts/lib/
      #    public-config.ts` feeds the repo's `.env` into both vite builds, so
      #    without it the server and the web client carry empty Clerk/relay
      #    literals and the client's `hasCloudPublicConfig()` goes false, which
      #    is what strips the T3 Connect block from Settings › Connections.
      #    (The `connect` subcommand still registers either way — it just has
      #    no relay to reach.) Upstream's documented fix for source builds is
      #    to copy `.env.example` — public identifiers, not secrets — into
      #    place, so take that verbatim rather than restating the values here.
      #    Costs a full rebuild of the pnpm/electron tree.
      # 2. The relay client T3 Connect tunnels through is the one piece not
      #    covered by `.env`: upstream downloads its own cloudflared on first
      #    `t3 connect link`. Point it at the Nix one instead.
      #
      # Both land on the unwrapped derivation — the only layer whose shape is
      # the same across packagings — and the outer wrapper just execs it, so
      # the env var survives.
      withConnect = base:
        base.override {
          t3code-unwrapped = base.unwrapped.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                cp .env.example .env
              '';

            postInstall =
              (old.postInstall or "")
              + ''
                for program in "$out/bin/t3" "$desktop/bin/t3code-desktop"; do
                  wrapProgram "$program" \
                    --set-default T3CODE_CLOUDFLARED_PATH "${getExe cfg.cloudflaredPackage}"
                done
              '';
          });
        };
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        package = mkOption {
          type = types.package;
          default = pkgs.unstable.t3code;
          defaultText = literalExpression "pkgs.unstable.t3code";
          description = mdDoc ''
            Stock t3code package providing the `t3` CLI and the desktop app.
            It is rebuilt with the T3 Connect public config and a pinned
            cloudflared before being installed.
          '';
        };

        # The desktop app has to come from this same derivation. Installing a
        # stock `t3code-desktop` alongside it silently splits the two: the CLI
        # gets T3 Connect and the app — which spawns its own backend out of its
        # own output, not the `serve` unit — does not.
        finalPackage = mkOption {
          type = types.package;
          readOnly = true;
          default = withConnect cfg.package;
          defaultText = literalExpression "cfg.package rebuilt with the T3 Connect public config and a pinned cloudflared";
          description = mdDoc "The package actually installed, after both fixes above.";
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
          # `out` is the CLI; the Electron app is the `desktop` output, and it
          # is only useful on a graphical host.
          home.packages =
            [cfg.finalPackage]
            ++ optional osConfig.modules.presets.desktop.enable cfg.finalPackage.desktop;

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
                  (getExe' cfg.finalPackage "t3")
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
