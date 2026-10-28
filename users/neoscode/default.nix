{
  lib,
  pkgs,
  config,
  inputs,
  osConfig,
  homeModules,
  ...
}: let
  user = "neoscode";
  desktop = osConfig.modules.presets.desktop.enable;
  inherit (osConfig.networking) hostName;
  # Every key below lives in 1Password; hosts without its agent can't sign with them.
  onePassword = osConfig.programs._1password-gui.enable;
in {
  imports = with homeModules.programs; [
    inputs.home.homeManagerModules.profile
    zsh
    bash
    tmux
    herdr
    btop
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
    gh
    ssh
    jujutsu
    sesh
    vivaldi
  ];

  age.identityPaths = ["${osConfig.users.users.${user}.home}/.ssh/agenix"];

  home = {
    username = osConfig.users.users.${user}.name;
    homeDirectory = osConfig.users.users.${user}.home;

    shellAliases = {
      ts = "tmux-session";
      ds = "dev-shell";
      dsl = "dev-shell laravel";
      dsk = "dev-shell kubernetes";
      o = "xdg-open";
      spf = "search-package-files";
      ss = "sesh-sessions";
    };
  };

  # TODO: drop the whole-vault entries once the old per-server keys are retired.
  xdg.configFile."1Password/ssh/agent.toml" = lib.mkIf onePassword {
    text = ''
      [[ssh-keys]]
      item = "neoscode@${hostName}"
      vault = "Personal"

      [[ssh-keys]]
      item = "GitHub Auth Key"
      vault = "Personal"

      [[ssh-keys]]
      item = "GitHub Signing Key"
      vault = "Personal"

      [[ssh-keys]]
      vault = "Personal"

      [[ssh-keys]]
      vault = "SSH"
    '';
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
  in {
    bash.initExtra = reattachWayland;

    zsh = {
      initContent =
        reattachWayland
        + ''
          [[ -n $CLAUDECODE ]] && setopt NO_NOMATCH NO_EQUALS SH_WORD_SPLIT
        '';
    };

    helix.enable = true;

    # IdentitiesOnly stops the agent offering every key and tripping MaxAuthTries.
    ssh.settings = lib.mkIf onePassword {
      "*" = {
        IdentitiesOnly = "yes";
        IdentityFile = "${./ssh + "/${hostName}.pub"}";
      };
      "github.com".IdentityFile = "${./ssh/github-auth.pub}";
    };

    gh.extensions = [pkgs.github-copilot-cli];
  };

  modules = {
    functionality.defaults = with pkgs; {
      editor = lib.mkIf desktop vscode-fhs;
      fileManager = lib.mkIf desktop (nautilus // {desktopFileName = "org.gnome.Nautilus";});
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

      nushell.extraConfig = builtins.readFile ../../parts/inventory/inventory.nu;
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
