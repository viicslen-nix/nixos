{
  flake.modules.homeManager.nilastia = {
    lib,
    config,
    inputs,
    osConfig ? {},
    ...
  }:
    with lib; let
      name = "nilastia";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};
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

      config = mkIf cfg.enable {
        # Upstream names its options `caelestia`; nilastia is a fork of that shell.
        programs.caelestia = {
          enable = true;

          systemd = {
            enable = true;
            # Compositors start this target without naming a shell.
            target = "desktop-shell.target";
          };
        };
      };
    };
}
