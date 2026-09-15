{
  flake.modules.nixos.shell = {
    lib,
    options,
    ...
  }:
    with lib; let
      namespace = "desktop";
      name = "shell";
    in {
      options.modules.${namespace}.${name} = mkOption {
        type = types.enum ["dms" "nilastia" "exo" "none"];
        default = "dms";
        description = mdDoc ''
          Which desktop shell autostarts in a graphical session.

          Compositors start `desktop-shell.target` and nothing else; each shell
          binds its own service to that target, so only the selected one exists
          to be pulled in. `none` starts a session with no shell.
        '';
      };

      config = mkIf (options ? home-manager) {
        home-manager.sharedModules = [
          {
            # Empty on purpose — compositors start this without naming a shell.
            systemd.user.targets.desktop-shell = {
              Unit = {
                Description = "Desktop shell";
                # Without these a shell can start before WAYLAND_DISPLAY exists and sees no display.
                BindsTo = ["graphical-session.target"];
                After = ["graphical-session.target"];
              };
            };
          }
        ];
      };
    };
}
