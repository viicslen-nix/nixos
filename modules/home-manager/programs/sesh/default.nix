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
      preview_command = "eza --all --git --icons --color=always {}"
      disable_startup_command = true

      [[session]]
      name = "mylisterhub-main-app"
      path = "~/Development/mylisterhub-main-app"

      [[session]]
      name = "mylisterhub-cloud-config"
      path = "~/Development/mylisterhub-cloud-config"

      [[session]]
      name = "inventory-main-app"
      path = "~/Development/inventory-main-app"

      [[session]]
      name = "Downloads 📥"
      path = "~/Downloads"
      startup_command = "ls"
    '';

    programs = {
      tmux.extraConfig = mkIf cfg.enableTmuxIntegration (mkAfter ''
        bind-key "T" run-shell "sesh connect \"$(
          sesh list --icons -ctH | fzf-tmux -p 80%,70% \
            --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
            --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
            --bind 'tab:down,btab:up' \
            --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons -ctH)' \
            --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
            --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
            --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
            --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
            --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons -ctH)' \
            --preview-window 'right:55%' \
            --preview 'sesh preview {}'
        )\""
      '');

      nushell.extraConfig = mkIf cfg.enableNushellIntegration (mkAfter ''
        def sesh-sessions [] {
          # Use fzf to list and select a session
          let session = (sesh list -ctH | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ' | str trim)

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
