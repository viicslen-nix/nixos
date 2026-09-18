{
  flake.modules.homeManager.noctalia = {
    lib,
    config,
    options,
    inputs,
    osConfig ? {},
    ...
  }:
    with lib; let
      name = "noctalia";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      noctalia = getExe config.programs.noctalia.package;
    in {
      imports = [inputs.noctalia.homeModules.default];

      options.modules.${namespace}.${name} = {
        enable = mkOption {
          type = types.bool;
          default = (osConfig.modules.desktop.shell or null) == name;
          defaultText = literalExpression "config.modules.desktop.shell == \"noctalia\"";
          description = mdDoc "Whether to enable the ${name} desktop shell.";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          programs.noctalia = {
            enable = true;
            systemd.enable = true;
          };

          # Upstream binds to wayland.systemd.target, which every wayland service
          # shares; retarget this unit rather than redirecting that option.
          systemd.user.services.noctalia = {
            Unit = {
              PartOf = mkForce ["desktop-shell.target"];
              After = mkForce ["desktop-shell.target"];
            };

            Install.WantedBy = mkForce ["desktop-shell.target"];
          };
        }

        # The shell owns its own binds; niri never learns which shell is running.
        (optionalAttrs (options.programs ? niri) {
          programs.niri.settings.binds = with config.lib.niri.actions; {
            "Mod+Space" = {
              repeat = false;
              action = spawn noctalia "msg" "panel-toggle" "launcher";
            };
            "Mod+G".action = spawn noctalia "msg" "panel-toggle" "control-center";
            "Mod+Shift+Q".action = spawn noctalia "msg" "panel-toggle" "session";
            "Mod+Shift+N".action = spawn noctalia "msg" "settings-toggle";
            "Mod+Alt+L" = {
              allow-when-locked = true;
              action = spawn noctalia "msg" "session" "lock";
            };
          };
        })
      ]);
    };
}
