{
  flake.modules.homeManager.nushell = {
    lib,
    pkgs,
    config,
    inputs,
    ...
  }:
    with lib; let
      name = "nushell";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc "nushell");
      };

      config = mkIf cfg.enable {
        home.shell.enableNushellIntegration = true;

        programs = {
          nushell = {
            enable = true;

            plugins = with pkgs.nushellPlugins; [
              query
              formats
              # highlight
            ];

            extraConfig = ''
              ${(builtins.unsafeDiscardStringContext (builtins.readFile ./config.nu))}

              source ${inputs.nu-scripts}/custom-completions/nix/nix-completions.nu
            '';

            extraEnv = ''
              $env.PATH = ($env.PATH | prepend ($env.HOME | path join ".local" "bin"))
            '';
          };

          # Needed for completions
          fish.enable = true;

          # Integrations
          keychain.enableNushellIntegration = true;
          direnv.enableNushellIntegration = true;
          carapace.enableNushellIntegration = true;
          atuin.enableNushellIntegration = true;
          zoxide.enableNushellIntegration = true;
          yazi.enableNushellIntegration = true;
        };
      };
    };
}
