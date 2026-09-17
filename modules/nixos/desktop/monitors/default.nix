{
  flake.modules.nixos.monitors = {
    lib,
    config,
    options,
    ...
  }:
    with lib; let
      cfg = config.modules.desktop.monitors;
    in {
      options.modules.desktop.monitors = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            position = {
              x = mkOption {
                type = types.int;
                default = 0;
              };
              y = mkOption {
                type = types.int;
                default = 0;
              };
            };
            scale = mkOption {
              type = types.number;
              default = 1;
            };
            rotation = mkOption {
              type = types.enum [0 90 180 270];
              default = 0;
              description = mdDoc "Counter-clockwise degrees; applied before positioning, so a rotated output's logical size is swapped.";
            };
          };
        });
        default = {};
        example = literalExpression ''{ DP-2 = { rotation = 90; }; DP-1.position = { x = 1080; y = 635; }; }'';
        description = mdDoc "Output layout, keyed by connector name, shared by niri and Hyprland.";
      };

      config = mkIf (options ? home-manager && cfg != {}) {
        home-manager.sharedModules = [
          ({osConfig, ...}: {
            programs.niri.settings.outputs = mkIf osConfig.programs.niri.enable (mapAttrs (_: m: {
                inherit (m) position scale;
                transform.rotation = m.rotation;
              })
              cfg);

            wayland.windowManager.hyprland.settings.monitor = mkIf osConfig.programs.hyprland.enable (mapAttrsToList (output: m: {
                inherit output;
                mode = "preferred";
                position = "${toString m.position.x}x${toString m.position.y}";
                inherit (m) scale;
                transform = m.rotation / 90;
              })
              cfg);
          })
        ];
      };
    };
}
