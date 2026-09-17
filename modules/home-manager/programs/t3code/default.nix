{
  flake.modules.homeManager.t3code = {
    lib,
    pkgs,
    config,
    options,
    osConfig,
    inputs,
    ...
  }:
    with lib;
    with inputs.self.lib; let
      name = "t3code";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      # Both fixes must land on the unwrapped derivation, not on the outer wrapper.
      withConnect = base:
        base.override {
          t3code-unwrapped = base.unwrapped.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                cp .env.example .env

                # niri-flake labels git builds `unstable <date>`, which this gate cannot read.
                if [ -f apps/desktop/src/snapShot/NiriSnapShot.ts ]; then
                  substituteInPlace apps/desktop/src/snapShot/NiriSnapShot.ts \
                    --replace-fail '/^(?:niri )?(\d+)\.(\d+)/' '/^(?:niri )?(?:unstable )?(\d+)[.-](\d+)/'
                fi
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

        # Never install a stock `t3code-desktop` alongside this; the app must come from here.
        finalPackage = mkOption {
          type = types.package;
          readOnly = true;
          default = withConnect cfg.package;
          defaultText = literalExpression "cfg.package rebuilt with the T3 Connect public config and a pinned cloudflared";
          description = mdDoc "The package actually installed, after both fixes above.";
        };

        # Off when the `serve` unit is the server: the app cannot attach to it and spawns a second backend on the same database.
        desktopApp = mkOption {
          type = types.bool;
          default = osConfig.modules.presets.desktop.enable && !cfg.serve.enable;
          defaultText = literalExpression "osConfig.modules.presets.desktop.enable && !cfg.serve.enable";
          description = mdDoc "Install the Electron desktop app. Use the `webapps` entry against the served port instead when `serve` is on.";
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

        snapShotShortcut = mkOption {
          type = types.nullOr types.str;
          default = "Ctrl+Shift+2";
          description = mdDoc ''
            niri key combination that triggers a T3 Code SnapShot. Declared
            here because T3 Code cannot write the Nix-generated niri config.
            Only applied when niri is enabled; `null` binds nothing.
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
            ++ optional cfg.desktopApp cfg.finalPackage.desktop;

          programs.niri.settings.binds = mkIf (osConfig.programs.niri.enable && cfg.desktopApp && cfg.snapShotShortcut != null) {
            ${cfg.snapShotShortcut} = {
              repeat = false;
              action.spawn = [
                (getExe' pkgs.glib "gdbus")
                "call"
                "--session"
                "--dest"
                "com.t3tools.T3Code.SnapShot"
                "--object-path"
                "/com/t3tools/SnapShot"
                "--method"
                "com.t3tools.SnapShot.Capture"
              ];
            };
          };

          # Don't swap this for `t3 service install`: its unit runs a self-updating launcher.
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

        # Test `options`, not `config`: gating the attr name on config.…webapps.enable recurses.
        (optionalAttrs (options.modules.programs ? webapps) {
          modules.programs.webapps.apps = mkIf (config.modules.programs.webapps.enable && cfg.serve.enable) [
            {
              name = "t3code";
              url = "http://127.0.0.1:${toString cfg.serve.port}";
              floating = false;
              icon = "${cfg.finalPackage.desktop}/share/icons/hicolor/scalable/apps/t3code.svg";
            }
          ];
        })
      ]);
    };
}
