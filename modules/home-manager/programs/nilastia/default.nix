{
  flake.modules.homeManager.nilastia = {
    lib,
    config,
    options,
    inputs,
    osConfig ? {},
    ...
  }:
    with lib; let
      name = "nilastia";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      shell = getExe config.programs.caelestia.package;
    in {
      imports = [inputs.nilastia.homeManagerModules.default];

      options.modules.${namespace}.${name} = {
        enable = mkOption {
          type = types.bool;
          default = (osConfig.modules.desktop.shell or null) == name;
          defaultText = literalExpression "config.modules.desktop.shell == \"nilastia\"";
          description = mdDoc "Whether to enable the ${name} desktop shell.";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          # Upstream names its options `caelestia`; nilastia is a fork of that shell.
          programs.caelestia = {
            enable = true;

            systemd = {
              enable = true;
              # Compositors start this target without naming a shell.
              target = "desktop-shell.target";
            };
          };
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
      ]);
    };
}
