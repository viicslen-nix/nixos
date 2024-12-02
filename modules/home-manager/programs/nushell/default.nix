{
  lib,
  config,
  ...
}:
with lib; let
  name = "nushell";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "nushell");
  };

  config = mkIf cfg.enable {
    programs = {
      nushell = {
        enable = true;

        shellAliases = {
          pn = "pnpm";
          vim = "nvim";
          ts = "tmux-session";
          ds = "dev-shell";
          dsl = "dev-shell laravel";
          dsk = "dev-shell kubernetes";
          o = "xdg-open";
          spf = "search-package-files";
        };
      };

      keychain.enableNushellIntegration = true;
      direnv.enableNushellIntegration = true;
      carapace.enableNushellIntegration = true;
      atuin.enableNushellIntegration = true;
      thefuck.enableNushellIntegration = true;
      zoxide.enableNushellIntegration = true;
      yazi.enableNushellIntegration = true;
    };
  };
}