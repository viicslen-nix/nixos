{
  lib,
  pkgs,
  osConfig,
  homeModules,
  ...
}: let
  user = "neoscode";
in {
  imports = with homeModules.programs; [
    zsh
    bash
    tmux
    herdr
    btop
    tmate
    atuin
    ghostty
    wezterm
    ideavim
    nushell
    starship
    worktrunk
    git
    jujutsu
    sesh
  ];

  age = {
    identityPaths = ["${osConfig.users.users.${user}.home}/.ssh/agenix"];

    secrets.intelephense = {
      file = ../../secrets/intelephense/licence.age;
      path = "${osConfig.users.users.${user}.home}/intelephense/licence.txt";
    };

    secrets.avante-anthropic-api-key = {
      file = ../../secrets/avante/anthropic-api-key.age;
    };
  };

  home = {
    username = osConfig.users.users.${user}.name;
    homeDirectory = osConfig.users.users.${user}.home;

    # Every shell gets these: home-manager feeds home.shellAliases into bash,
    # zsh, fish and nushell alike.
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
      ss = "sesh-sessions";

      g = "git";
      gdf = "git diff";
      gst = "git status";
      gpl = "git pull";
      gph = "git push";

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

    packages = with pkgs; [
      inputs.opencode.oh-my-opencode
      inputs.packages.python.mempalace
    ];

    # ssh refuses to open a control socket if the ControlPath directory is
    # missing, which breaks any host using ControlMaster. See the ControlPath
    # declaration in programs.ssh.settings below.
    file.".ssh/controlmasters/.keep".text = "";

    autostart = [
      {
        package = pkgs._1password-gui;
        args = ["--silent"];
        delay = 5;
      }
    ];

    sessionVariables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
    };
  };

  xdg = {
    configFile = {
      "gh/hosts.yml".source = (pkgs.formats.yaml {}).generate "hosts.yml" {
        "github.com" = {
          user = "viicslen";
          git_protocol = "https";
          users = {
            viicslen = "";
          };
        };
      };
    };
  };

  programs = let
    # Superset builds its PTY env from a scrubbed login-shell snapshot, which
    # carries no WAYLAND_DISPLAY — so wl-copy/wl-paste, and with them Claude
    # Code's image paste, have no compositor to talk to. Point them back at the
    # session socket when one exists.
    reattachWayland = ''
      if [ -z "$WAYLAND_DISPLAY" ]; then
        : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
        export XDG_RUNTIME_DIR
        for sock in "$XDG_RUNTIME_DIR"/wayland-[0-9]*; do
          [ -S "$sock" ] || continue
          export WAYLAND_DISPLAY="''${sock##*/}"
          break
        done
      fi
    '';

    # lsd stands in for coreutils ls in the posix shells only — nushell keeps
    # its own structured `ls`.
    lsAliases = {
      ls = "lsd";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      lt = "ls --tree";
    };
  in {
    bash = {
      shellAliases = lsAliases;
      initExtra = reattachWayland;
    };

    zsh = {
      shellAliases = lsAliases;
      initContent = reattachWayland;
    };

    carapace.enable = true;
    zoxide.enable = true;
    helix.enable = true;

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings.prompts = "disabled";
      extensions = with pkgs; [
        gh-stack
        github-copilot-cli
      ];
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
      historyWidget.command = "";
    };

    hstr = {
      enable = true;
      enableZshIntegration = true;
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*".ControlPath = "/home/${user}/.ssh/controlmasters/%r@%h:%p";
        "work.neoscode.com".ProxyCommand = "${lib.getExe pkgs.cloudflared} access ssh --hostname %h";
      };
    };
  };

  modules = {
    functionality.defaults = with pkgs; {
      terminal = pkgs.inputs.ghostty.default;
      editor = vscode-fhs;
      fileManager = nautilus;
      browser = vivaldi;
      passwordManager = _1password-gui;
    };
    programs = {
      worktrunk.tmux.enable = true;

      git = {
        user = osConfig.users.users.${user}.description;
        email = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
      jujutsu = {
        userName = osConfig.users.users.${user}.description;
        userEmail = "39545521+viicslen@users.noreply.github.com";
        signingKey = builtins.readFile ./ssh/git-signing-key.pub;
      };
      sesh = {
        enableNushellIntegration = true;
        enableTmuxIntegration = true;
      };
    };
  };
}
