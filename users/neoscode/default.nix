{
  lib,
  pkgs,
  config,
  osConfig,
  homeModules,
  ...
}: let
  user = "neoscode";
  desktop = osConfig.modules.presets.desktop.enable;
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
    workmux
    caelestia
    exo
    noctalia
    git
    jujutsu
    sesh
    vivaldi
  ];

  age.identityPaths = ["${osConfig.users.users.${user}.home}/.ssh/agenix"];

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
    };

    packages = with pkgs; [
      inputs.opencode.oh-my-opencode
      inputs.packages.python.mempalace
    ];

    # Don't drop: ssh will not open a control socket if this directory is missing.
    file.".ssh/controlmasters/.keep".text = "";

    sessionVariables.EDITOR = "nvim";
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
    # Don't drop: superset's scrubbed PTY env carries no WAYLAND_DISPLAY.
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
      settings."*".ControlPath = "${osConfig.users.users.${user}.home}/.ssh/controlmasters/%r@%h:%p";
    };
  };

  modules = {
    functionality.defaults = with pkgs; {
      editor = lib.mkIf desktop vscode-fhs;
      fileManager = lib.mkIf desktop nautilus;
      passwordManager = lib.mkIf desktop _1password-gui;
      terminal = lib.mkIf desktop pkgs.inputs.ghostty.default;
      browser = lib.mkIf desktop config.modules.programs.vivaldi.finalPackage;
    };
    programs = {
      ghostty.enable = desktop;
      wezterm.enable = desktop;
      worktrunk.tmux.enable = true;
      # Imported but off: `wt-dashboard` (worktrunk's popup) replaced its dashboard.
      workmux.enable = false;

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
      vivaldi = {
        enable = desktop;
        # 8.3's pinned-tab row moves pinned tabs out of .tab-strip, which is
        # where FavouriteTabs.css builds its grid; no settings UI toggles it.
        # preferences.vivaldi.tabs.show_pinned_group = false;

        jsMods = [
          "ModConfig.js"
          "TabManager.js"
          "VividPeek.js"
          "PinnedTabRestore.js"
          "InteractionFeedback.js"
        ];
        cssMods = [
          "PeekTabbar.css"
          "BetterAnimation.css"
          "VividPeek.css"
          "VividQC.css"
          "RemoveClutter.css"
          "PinnedTabRestore.css"
          "InteractionFeedback.css"
          "DownloadPanel.css"
          "Extensions.css"
          # "FavouriteTabs.css"
        ];
      };
    };
  };
}
