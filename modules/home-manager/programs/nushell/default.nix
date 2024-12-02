{
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

  activateNushellPluginsNuScript = pluginNames: pkgs.writeTextFile {
    name = "activateNushellPlugins";
    destination = "/bin/activateNushellPlugins.nu";
    text = ''
      #!/usr/bin/env nu
      ${
        concatStringsSep "\n" (map (x: "plugin add ${pkgs.nushellPlugins.${x}}/bin/nu_plugin_${x}") pluginNames)
      }
    '';
  };

  msgPackz = pluginNames: pkgs.runCommand "nushellMsgPackz" {} ''
    mkdir -p "$out"
    # After some experimentation, I determined that this only works if --plugin-config is FIRST
    ${pkgs.nushell}/bin/nu --plugin-config "$out/plugin.msgpackz" ${activateNushellPluginsNuScript pluginNames}/bin/activateNushellPlugins.nu
  '';
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "nushell");

    plugins = mkOption {
      type = types.listOf types.str;
      default = [
        # "highlight"
        # "formats"
        # "units"
        # "query"
        # "gstat"
        # "net"
      ];
      description = ''
        A list of plugins to install for nushell.
      '';
    };
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

          sail = "vendor/bin/sail";
          s = "sail";
          sud = "sail up -d";
          sdown = "sail down";
          sa = "sail artisan";
          sc = "sail composer";
          sp = "sail php";
          sn = "sail npm";
          st = "sail tinker";
          sd = "sail debug";
          sda = "sail debug artisan";
        };

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

    xdg.configFile."nushell/plugin.msgpackz".source = "${msgPackz cfg.plugins}/plugin.msgpackz";
  };
}