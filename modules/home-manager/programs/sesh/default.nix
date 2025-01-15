{
  lib,
  config,
  ...
}:
with lib; let
  name = "sesh";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    enableNushellIntegration = mkEnableOption "Enable nushell integration";
    enableTmuxIntegration = mkEnableOption "Enable tmux integration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sesh
      eza
    ];

    xdg.configFile."sesh/sesh.toml".text = ''
      [default_session]
      startup_command = "nvim -c ':Telescope find_files'"
      preview_command = "eza --all --git --icons --color=always {}"
      disable_startup_command = true

      [[session]]
      name = "Downloads 📥"
      path = "~/Downloads"
      startup_command = "ls"

      [[session]]
      name = "tmux config"
      path = "~/c/dotfiles/.config/tmux"
      startup_command = "nvim tmux.conf"
      preview_command = "bat --color=always ~/c/dotfiles/.config/tmux/tmux.conf"
    '';

    programs = {
      tmux.extraConfig = mkIf cfg.enableTmuxIntegration (mkAfter ''
        bind-key "T" run-shell "sesh connect \"$(
          sesh list --icons | fzf-tmux -p 80%,70% \
            --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
            --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
            --bind 'tab:down,btab:up' \
            --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
            --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
            --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
            --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
            --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
            --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
            --preview-window 'right:55%' \
            --preview 'sesh preview {}'
        )\""
      '');

      nushell.extraConfig = mkIf cfg.enableNushellIntegration (mkAfter ''
        def sesh-sessions [] {
          # Use fzf to list and select a session
          let session = (sesh list -tcH | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ' | str trim)

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
