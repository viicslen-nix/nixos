{
  lib,
  pkgs,
  config,
  options,
  ...
}:
with lib; let
  cfg = config.features.onePassword;
  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.features.onePassword = {
    enable = mkEnableOption "1Password";
    socket = mkOption {
      type = types.str;
      default = "~/.1password/agent.sock";
      description = "The path to the 1Password socket";
    };
    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to run 1Password as";
    };
    autostart = mkOption {
      type = types.bool;
      default = true;
      description = "Enable autostart for 1Password";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Enable the 1Password CLI
      programs._1password.enable = true;

      # Enable the 1Password GUI and configure the polkit policy
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [cfg.user];
      };

      # Configure the environment variable for the 1Password socket
      environment.sessionVariables = {
        SSH_AUTH_SOCK = cfg.socket;
      };
    }
    (mkIf homeManagerLoaded {
      home-manager.users.${cfg.user} = {
        # Configure the environment variable for the 1Password socket
        home.sessionVariables = {
          SSH_AUTH_SOCK = cfg.socket;

          # Skip the SSH agent workaround
          GSM_SKIP_SSH_AGENT_WORKAROUND = "1";
        };

        xdg = {
          enable = mkDefault true;

          # Disable gnome-keyring ssh-agent
          configFile."autostart/gnome-keyring-ssh.desktop".text = ''
            ${lib.fileContents "${pkgs.gnome.gnome-keyring}/etc/xdg/autostart/gnome-keyring-ssh.desktop"}
            Hidden=true
          '';

          # Configure the 1Password autostart desktop file
          configFile."autostart/1password.desktop".text = mkIf cfg.autostart (
            replaceStrings
            ["Exec=1password %U"]
            ["Exec=${pkgs._1password-gui}/bin/1password --silent %U"]
            lib.fileContents "${pkgs._1password-gui}/share/applications/${pkgs._1password-gui.pname}.desktop"
          );
        };

        # Configure the SSH client to use the 1Password socket
        programs.ssh = {
          enable = true;
          extraConfig = ''
            Host *
              IdentityAgent ~/.1password/agent.sock

            Include ~/.ssh/config.d/hosts
          '';
        };
      };
    })
  ]);
}
