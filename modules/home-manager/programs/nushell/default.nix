{
  lib,
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
    enable = mkEnableOption (mdDoc "nushell");
  };

  config = mkIf cfg.enable {
    programs = {
      nushell = {
        enable = true;

        shellAliases = {
          pn = "pnpm";
          vim = "nvim";
          cat = "bat";
          ts = "tmux-session";
          ds = "dev-shell";
          dsl = "dev-shell laravel";
          dsk = "dev-shell kubernetes";
          o = "xdg-open";
          spf = "search-package-files";

          k = "kubectl";
          kga = "kubectl get all";
          kgp = "kubectl get pods";
          kdp = "kubectl describe pod";
          kcuc = "kubectl config use-context";
          krr = "kubectl rollout restart";

          dep = "vendor/bin/dep";
          sail = "vendor/bin/sail";
          s = "vendor/bin/sail";
          sud = "vendor/bin/sail up -d";
          sdown = "vendor/bin/sail down";
          art = "vendor/bin/sail artisan";
          sa = "vendor/bin/sail artisan";
          sc = "vendor/bin/sail composer";
          sp = "vendor/bin/sail php";
          sn = "vendor/bin/sail npm";
          st = "vendor/bin/sail tinker";
          sd = "vendor/bin/sail debug";
          sda = "vendor/bin/sail debug artisan";
        };

        # plugins = with pkgs.nushellPlugins; [
        #   net
        #   dbus
        #   units
        #   query
        #   qstat
        #   formats
        #   highlight
        # ];

        extraConfig = ''
          ${(builtins.unsafeDiscardStringContext (builtins.readFile ./config.nu))}

          source ${inputs.nu-scripts}/custom-completions/nix/nix-completions.nu
        '';
      };

      # Needed for completions
      fish.enable = true;

      # Integrations
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
