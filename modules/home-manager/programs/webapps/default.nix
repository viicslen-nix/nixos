{
  flake.modules.homeManager.webapps = {
    lib,
    pkgs,
    config,
    osConfig,
    inputs,
    ...
  }:
    with lib;
    with inputs.self.lib; let
      name = "webapps";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      chromium = "${cfg.package}/bin/chromium";

      # Don't pass --user-data-dir: the force-installed Violentmonkey lives in the default profile.
      mkLauncher = app:
        pkgs.writeShellScriptBin "webapp-${app.name}" ''
          exec ${chromium} --class=webapp-${app.name} --ozone-platform-hint=auto \
            --app=${app.url} "$@"
        '';

      # Normal chromium window (toolbar) on the same profile, to manage Violentmonkey
      # and install userscripts — --app windows have no UI for that.
      manageLauncher = pkgs.writeShellScriptBin "webapp-manage" ''
        exec ${chromium} --ozone-platform-hint=auto "$@"
      '';

      mkDesktopEntry = app:
        nameValuePair "webapp-${app.name}" {
          name = "Web App: ${app.name}";
          exec = "webapp-${app.name}";
          settings.StartupWMClass = "webapp-${app.name}";
          terminal = false;
          categories = ["Network"];
        };
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        package = mkOption {
          type = types.package;
          default = pkgs.chromium;
          description = "Chromium-based package used to run the web apps in --app mode.";
        };

        apps = mkOption {
          type = types.listOf (types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Short slug; the launcher becomes webapp-<name> and the niri app-id webapp-<name>.";
              };
              url = mkOption {
                type = types.str;
                description = "URL to open in a chromeless app window.";
              };
              injectScript = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  Optional userscript (.user.js) auto-injected into this app via a
                  generated content-script extension (--load-extension). Also dropped
                  at ~/.config/webapps/<name>.user.js so it can be pasted into Violentmonkey.
                '';
              };
            };
          });
          default = [
            {
              name = "whatsapp";
              url = "https://web.whatsapp.com";
              injectScript = ./whatsapp-focus.user.js;
            }
          ];
          description = "Web apps to expose as floating windows. Add one entry per app.";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          home.packages = (map mkLauncher cfg.apps) ++ [manageLauncher cfg.package];

          # Copy on disk for pasting into Violentmonkey (VM has no file-based seeding).
          home.file = listToAttrs (map (app:
            nameValuePair ".config/webapps/${app.name}.user.js" {source = app.injectScript;})
          (filter (app: app.injectScript != null) cfg.apps));

          xdg.desktopEntries =
            listToAttrs (map mkDesktopEntry cfg.apps)
            // {
              webapp-manage = {
                name = "Web Apps (manage)";
                exec = "webapp-manage";
                terminal = false;
                categories = ["Network"];
              };
            };

          # Float every webapp-* window in niri.
          programs.niri.settings.window-rules = mkIf osConfig.programs.niri.enable [
            {
              matches = [{app-id = "^webapp-";}];
              open-floating = true;
              open-focused = true;
              default-column-width = {proportion = 0.5;};
            }
          ];
        }

        (persistence.mkPersistence config {
          config = ["chromium"];
        })
      ]);
    };
}
