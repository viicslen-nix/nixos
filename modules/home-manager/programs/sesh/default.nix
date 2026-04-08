{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "sesh";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};

  # Display flags apply to every sesh list call
  displayFlagsStr = lib.escapeShellArgs (lib.flatten [
    (lib.optional cfg.list.hideAttached "--hide-attached")
    (lib.optional cfg.list.hideDuplicates "--hide-duplicates")
    (lib.optional cfg.list.icons "--icons")
  ]);

  # Source flags used for the default "show all" call
  sourceFlagsStr = lib.escapeShellArgs (lib.flatten [
    (lib.optional cfg.list.config "--config")
    (lib.optional cfg.list.tmux "--tmux")
    (lib.optional cfg.list.tmuxinator "--tmuxinator")
    (lib.optional cfg.list.zoxide "--zoxide")
  ]);

  sesh-list = pkgs.writeShellScriptBin "sesh-list" ''
    ${pkgs.sesh}/bin/sesh list ${displayFlagsStr} "$@" || true
    ${lib.concatMapStringsSep "\n" (dir: ''
        _dir="${dir}"
        _dir="''${_dir/#\~/$HOME}"
        if [ -d "$_dir" ]; then
          find "$_dir" -maxdepth 1 -mindepth 1 -type d | sed "s|$HOME|~|"
        fi
      '')
      cfg.list.extraDirs}
  '';
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    enableNushellIntegration = mkEnableOption "Enable nushell integration";
    enableTmuxIntegration = mkEnableOption "Enable tmux integration";

    list = {
      config = (mkEnableOption "Show sesh configs") // {default = true;};
      tmux = (mkEnableOption "Show tmux sessions") // {default = true;};
      tmuxinator = (mkEnableOption "Show tmuxinator configs") // {default = true;};
      zoxide = mkEnableOption "Show zoxide results";

      icons = (mkEnableOption "Show icons.") // {default = true;};
      hideAttached = mkEnableOption "Don't show currently attached sessions";
      hideDuplicates = mkEnableOption "Hide duplicate entries";

      extraDirs = mkOption {
        type = types.listOf types.str;
        default = ["~/Development"];
        description = "Directories whose immediate subdirectories are appended to the session list.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sesh
      eza
      sesh-list
    ];

    xdg.configFile."sesh/sesh.toml".source = ./sesh.toml;

    programs = {
      tmux.extraConfig = mkIf cfg.enableTmuxIntegration (mkAfter ''
        bind-key "T" run-shell "sesh connect \"$(
          ${lib.getExe sesh-list} ${sourceFlagsStr} | fzf-tmux -p 80%,70% \
            --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
            --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
            --bind 'tab:down,btab:up' \
            --bind 'ctrl-a:change-prompt(⚡  )+reload(${lib.getExe sesh-list} ${sourceFlagsStr})' \
            --bind 'ctrl-t:change-prompt(🪟  )+reload(${lib.getExe sesh-list} -t)' \
            --bind 'ctrl-g:change-prompt(⚙️  )+reload(${lib.getExe sesh-list} -c)' \
            --bind 'ctrl-x:change-prompt(📁  )+reload(${lib.getExe sesh-list} -z)' \
            --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
            --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(${lib.getExe sesh-list} ${sourceFlagsStr})' \
            --preview-window 'right:55%' \
            --preview 'sesh preview {}'
        )\""
      '');

      nushell.extraConfig = mkIf cfg.enableNushellIntegration (mkAfter ''
        def sesh-sessions [] {
          # Use fzf to list and select a session
          let session = (^"${lib.getExe sesh-list}" ${sourceFlagsStr} -H | fzf --height 40% --reverse --ansi --border-label ' sesh ' --border --prompt '⚡  ' --preview 'sesh preview {}' | str trim)

          # Check if a session was selected
          if ($session == \'\') {
            return
          }

          # Connect to the selected session
          sesh connect $session
        }
      '');
    };
  };
}
