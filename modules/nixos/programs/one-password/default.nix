{
  lib,
  pkgs,
  config,
  inputs,
  options,
  ...
}:
with lib; let
  name = "onePassword";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};

  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption "1Password";
    gitSignCommits = mkEnableOption "Git commit signing";
    gitSignKey = mkOption {
      type = types.str;
      description = "The public key to use for signing git commits";
    };
    socket = mkOption {
      type = types.str;
      default = "~/.1password/agent.sock";
      description = "The path to the 1Password socket";
    };
    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "The users to run 1Password as";
    };
    autostart = mkOption {
      type = types.bool;
      default = true;
      description = "Enable autostart for 1Password";
    };
    plugins = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "The list of shell plugins to install";
    };
    allowedCustomBrowsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "The list of browsers to allow 1Password to open";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Enable the 1Password CLI
      programs._1password.enable = true;
      # programs._1password.package = pkgs.stable._1password;

      # Enable the 1Password GUI and configure the polkit policy
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = cfg.users;
        # package = pkgs.stable._1password-gui;
      };

      # Configure the environment variable for the 1Password socket
      environment.sessionVariables = {
        SSH_AUTH_SOCK = cfg.socket;
      };

      environment.etc = {
        "1password/custom_allowed_browsers" = {
          # get the list from the cfg and join it with new lines
          text = ''
            ${concatStringsSep "\n" cfg.allowedCustomBrowsers}
          '';
          mode = "0755";
        };
      };
    }
    (mkIf homeManagerLoaded {
      home-manager.users = lib.genAttrs cfg.users (_user: {
        imports = [
          inputs.one-password-shell-plugins.hmModules.default
        ];

        # Configure the environment variable for the 1Password socket
        home.sessionVariables = {
          SSH_AUTH_SOCK = cfg.socket;

          # Skip the SSH agent workaround
          GSM_SKIP_SSH_AGENT_WORKAROUND = "1";
        };

        xdg = {
          enable = mkDefault true;

          # Configure the 1Password autostart desktop file
          configFile."autostart/1password.desktop".text = mkIf cfg.autostart (
            replaceStrings
            ["Exec=1password %U"]
            ["Exec=${pkgs._1password-gui}/bin/1password --silent %U"]
            (lib.fileContents "${pkgs._1password-gui}/share/applications/${pkgs._1password-gui.pname}.desktop")
          );
        };

        programs._1password-shell-plugins = {
          # enable 1Password shell plugins for bash, zsh, and fish shell
          enable = true;
          # the specified packages as well as 1Password CLI will be
          # automatically installed and configured to use shell plugins
          plugins = cfg.plugins;
        };

        # Configure the SSH client to use the 1Password socket
        programs.ssh.matchBlocks."*".extraOptions = {
          IdentityAgent = cfg.socket;
        };

        # Configure git to sign commits with the 1Password SSH key
        programs.git.includes = mkIf cfg.gitSignCommits [
          {
            contents = {
              commit.gpgSign = true;
              gpg.format = "ssh";
              "gpg \"ssh\"".program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
            };
          }
        ];

        programs.jujutsu.settings.signing.backends.ssh.program = mkIf cfg.gitSignCommits "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";

        # Configure the 1Password quick access keybinding for gnome
        dconf.settings = {
          "org/gnome/settings-daemon/plugins/media-keys" = {
            custom-keybindings = ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"];
          };

          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            binding = "<Shift><Control>space";
            command = "1password --quick-access";
            name = "1Password";
          };
        };
      });
    })
  ]);
}
