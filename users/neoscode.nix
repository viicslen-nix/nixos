{
  lib,
  pkgs,
  config,
  ...
}: let
  user = "neoscode";
  description = "Victor R";
  password = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
in {
  imports = [
    (import ./defaults.nix {inherit lib user description password;})
  ];

  users.users.${user}.extraGroups = ["wheel"];

  age.identityPaths = ["${config.users.users.${user}.home}/.ssh/agenix"];

  modules = {
    desktop = {
      gnome.user = user;
      hyprland.user = user;
    };

    programs = {
      docker.user = user;
      mkcert.rootCA.users = [user];

      onePassword = {
        inherit user;
        gitSignKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJk8lwwP7GnxZMgpx+C30i/Lw912BBoFccz4gjek8lCX";
      };
    };

    functionality = {
      impermanence.user = user;
      backups = {
        home.users = [user];

        paths = [
          "/persist/home/${user}/Development"
        ];
      };
    };
  };

  home-manager.users.${user} = {
    home = {
      sessionVariables = {
        EDITOR = "nvim";
        NIXOS_OZONE_WL = "1";
      };

      packages = with pkgs; [
        microsoft-edge-wayland
        discord
        remmina
        moonlight-qt
      ];

      autostart = with pkgs; [
        mullvad-vpn
        discord
      ];
    };

    programs = {
      ray.enable = true;
      tinkerwell.enable = true;

      gh.extensions = [pkgs.gh-copilot];

      ssh = {
        controlPath = "/home/${user}/.ssh/controlmasters/%r@%h:%p";
        matchBlocks = {
          "FmTod" = {
            hostname = "webapps";
            user = "fmtod";
          };

          "SellDiam" = {
            hostname = "webapps";
            user = "inventory";
          };
        };
      };

      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };

      git = {
        userName = description;
        userEmail = "39545521+viicslen@users.noreply.github.com";
        aliases = {
          nah = ''!f(){ git reset --hard; git clean -df; if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then git rebase --abort; fi; }; f'';
          forget = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D";
          forgetlist = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}'";
          uncommit = "reset --soft HEAD~0";
        };
        extraConfig = {
          pull.rebase = true;
          init.defaultBranch = "main";
          web.browser = "microsoft-edge";
        };
      };

      nvchad = {
        enable = true;
        backup = false;
        extraPackages = with pkgs; [
          nixd
          python3
          php83
          php83Packages.composer
          docker-compose-language-service
          dockerfile-language-server-nodejs
          nodePackages.bash-language-server
          stable.nodePackages.volar
        ];
      };
    };

    xdg = {
      configFile."gh/hosts.yml".source = (pkgs.formats.yaml {}).generate "hosts.yml" {
        "github.com" = {
          user = "viicslen";
          git_protocol = "https";
          users = {
            viicslen = "";
          };
        };
      };

      mimeApps = {
        enable = true;
        associations.added = {
          "text/html" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
          "application/xhtml+xml" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
          "x-scheme-handler/sms" = "org.gnome.Shell.Extensions.GSConnect.desktop";
          "x-scheme-handler/tel" = "org.gnome.Shell.Extensions.GSConnect.desktop";
          "x-scheme-handler/http" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
          "x-scheme-handler/https" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
          "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
        };
        defaultApplications = {
          "text/html" = "microsoft-edge.desktop";
          "application/xhtml+xml" = "microsoft-edge.desktop";
          "x-scheme-handler/http" = "microsoft-edge.desktop";
          "x-scheme-handler/https" = "microsoft-edge.desktop";
          "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
        };
      };
    };

    dconf.settings = {
      "org/gnome/shell" = {
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "microsoft-edge.desktop"
          "phpstorm.desktop"
          "kitty.desktop"
          "slack.desktop"
        ];
      };

      "org/gnome/shell/extensions/arcmenu" = {
        menu-button-border-color = lib.hm.gvariant.mkTuple [true "transparent"];
        menu-button-border-radius = lib.hm.gvariant.mkTuple [true 10];
      };

      "org/gnome/desktop/wm/preferences".button-layout = lib.mkForce ":minimize,maximize,close";
    };
  };
}
