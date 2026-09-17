{
  flake.modules.homeManager.caelestia = {
    lib,
    config,
    options,
    pkgs,
    inputs,
    osConfig ? {},
    ...
  }:
    with lib; let
      name = "caelestia";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      inherit (pkgs.stdenv.hostPlatform) system;
      # Nilastia imports QtMultimedia (video wallpapers) but its package never adds the module.
      nilastia = inputs.nilastia.packages.${system}.with-cli.override (old: {
        quickshell = old.quickshell // {withModules = mods: old.quickshell.withModules (mods ++ [pkgs.qt6.qtmultimedia]);};
      });
      caelestia = inputs.caelestia.packages.${system}.with-cli;
      onNiri = osConfig.programs.niri.enable or false;
      onHyprland = osConfig.programs.hyprland.enable or false;

      # A host with both compositors picks the build per session.
      dispatch = pkgs.writeShellScriptBin "caelestia-shell" ''
        if [ "''${XDG_CURRENT_DESKTOP-}" = niri ]; then exec ${getExe nilastia} "$@"; fi
        exec ${getExe caelestia} "$@"
      '';

      # Replaces the default logind Terminate, which kills niri-session but leaves niri.service holding graphical-session.target.
      logout = pkgs.writeShellScript "caelestia-logout" ''
        ${optionalString onNiri ''[ "''${XDG_CURRENT_DESKTOP-}" = niri ] && exec ${getExe osConfig.programs.niri.package} msg action quit --skip-confirmation''}
        exec ${getExe osConfig.programs.uwsm.package} stop
      '';

      shell = getExe config.programs.caelestia.package;
      hyprIpc = keys: args: opts: {
        _args = [keys (generators.mkLuaInline "hl.dsp.exec_cmd(${generators.toLua {} "${shell} ipc call ${args}"})")] ++ optional (opts != {}) opts;
      };
    in {
      # Import only one: nilastia's module is a copy of this one and declares the same options.
      imports = [inputs.caelestia.homeManagerModules.default];

      options.modules.${namespace}.${name} = {
        enable = mkOption {
          type = types.bool;
          default = (osConfig.modules.desktop.shell or null) == name;
          defaultText = literalExpression "config.modules.desktop.shell == \"caelestia\"";
          description = mdDoc "Whether to enable the ${name} desktop shell (its nilastia fork under niri).";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          programs.caelestia = {
            enable = true;
            package =
              if onNiri && onHyprland
              then dispatch
              else if onNiri
              then nilastia
              else caelestia;

            systemd = {
              enable = true;
              # Compositors start this target without naming a shell.
              target = "desktop-shell.target";
            };
          };
        }

        {
          xdg.configFile."caelestia/logout".source = logout;

          # Not programs.caelestia.settings: the shell saves shell.json itself, so it must stay a writable file.
          home.activation.caelestiaLogout = hm.dag.entryAfter ["writeBoundary"] ''
            f="${config.xdg.configHome}/caelestia/shell.json"
            [ -e "$f" ] || run install -Dm644 ${pkgs.writeText "shell.json" "{}"} "$f"
            filter='if (.session.commands.logout // ["logout"]) == ["logout"] then .session.commands.logout = [$c] else . end'
            c="${config.xdg.configHome}/caelestia/logout"
            if ! ${getExe pkgs.jq} -e --arg c "$c" "($filter) == ." "$f" >/dev/null; then
              new=$(${getExe pkgs.jq} --arg c "$c" "$filter" "$f")
              run install -m644 /dev/stdin "$f" <<<"$new"
            fi
          '';
        }

        # The shell owns its own binds; niri never learns which shell is running.
        # Absent on a host that runs a different compositor.
        (mkIf (options.programs ? niri) {
          programs.niri.settings.binds = with config.lib.niri.actions; {
            "Mod+Space" = {
              repeat = false;
              action = spawn shell "ipc" "call" "drawers" "toggle" "launcher";
            };
            "Mod+G".action = spawn shell "ipc" "call" "drawers" "toggle" "dashboard";
            "Mod+Shift+Q".action = spawn shell "ipc" "call" "drawers" "toggle" "session";
            "Mod+Shift+N".action = spawn shell "ipc" "call" "nexus" "open";
            "Mod+Alt+L" = {
              allow-when-locked = true;
              action = spawn shell "ipc" "call" "lock" "lock";
            };
          };
        })

        # SUPER+G is hyprsplit's on Hyprland.
        (mkIf onHyprland {
          wayland.windowManager.hyprland.settings.bind = [
            (hyprIpc "SUPER + space" "drawers toggle launcher" {})
            (hyprIpc "SUPER + CTRL + G" "drawers toggle dashboard" {})
            (hyprIpc "SUPER + SHIFT + Q" "drawers toggle session" {})
            (hyprIpc "SUPER + SHIFT + N" "nexus open" {})
            (hyprIpc "SUPER + ALT + L" "lock lock" {locked = true;})
          ];
        })
      ]);
    };
}
