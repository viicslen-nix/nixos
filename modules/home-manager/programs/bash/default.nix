{
  flake.modules.homeManager.bash = {
    lib,
    config,
    inputs,
    ...
  }:
    with lib;
    with inputs.self.lib; let
      name = "bash";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
      };

      config = mkIf cfg.enable (mkMerge [
        {
          programs.bash = {
            enable = true;

            historyControl = ["ignoredups" "ignorespace"];
            historyIgnore = ["ls" "cd" "exit"];
          };

          # Don't add enableBashIntegration lines; home.shell.enableShellIntegration covers them.
        }
        (persistence.mkPersistence config {
          files = [".bash_history"];
        })
      ]);
    };
}
