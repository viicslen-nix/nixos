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

          # atuin/carapace/direnv/starship/zoxide/yazi/keychain all default their
          # enableBashIntegration to home.shell.enableShellIntegration, so bash
          # picks up the same set nushell and zsh use without repeating it here.
        }
        (persistence.mkPersistence config {
          files = [".bash_history"];
        })
      ]);
    };
}
