{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "tmux";
  namespace = "features";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "tmux");
  };

  config.programs.tmux = mkIf cfg.enable {
    enable = true;
    shortcut = "Space";
    mouse = true;
    baseIndex = 1;
    keyMode = "vi";
    escapeTime = 1;
    historyLimit = 10000;
    aggressiveResize = true;
    tmuxinator.enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    # extraConfig = "source-file ~/.tmux.conf";

    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'off'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
      {
        plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "tokyo-night";
          rtpFilePath = "tokyo-night.tmux";
          version = "v1.5.5";
          src = inputs.tokyo-night-tmux;
        };
        extraConfig = ''
          set -g @tokyo-night-tmux_theme "storm" # options: night, storm, day
          set -g @tokyo-night-tmux_show_datetime 0
          set -g @tokyo-night-tmux_path_format "relative"
          set -g @tokyo-night-tmux_show_git 1
          set -g @tokyo-night-tmux_show_wbg 1
          set -g status-justify left
        '';
      }
    ];

    extraConfig = ''
      #--------------------------------------------------------------------------
      # Configuration
      #--------------------------------------------------------------------------

      # Start pane numbering from 1 for easier switching
      setw -g pane-base-index 1

      # Allow automatic renaming of windows
      set -g allow-rename on


      # Renumber windows when one is removed.
      set -g renumber-windows on

      # Improve colors
      set -g default-terminal "''${TERM}"

      # Enable undercurl
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'

      # Enable undercurl colors
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

      # Allow the mouse to resize windows and select tabs
      set -g mouse on

      # Allow tmux to set the terminal title
      set -g set-titles on

      # Monitor window activity to display in the status bar
      setw -g monitor-activity on

      # A bell in another window should cause a bell in the current window
      set -g bell-action any

      # Don't show distracting notifications
      set -g visual-bell off
      set -g visual-activity off

      # Focus events enabled for terminals that support them
      set -g focus-events on

      # don't detach tmux when killing a session
      set -g detach-on-destroy off

      #--------------------------------------------------------------------------
      # Status line
      #--------------------------------------------------------------------------

      # Status line customisation
      # set-option -g status-left-length 100
      # set-option -g status-right-length 100

      # set-option -g status-left "#{tmux_mode_indicator} #{session_name}  "
      # set-option -g status-right "#{pane_title} "

      # set-option -g status-style "fg=#545c7e bg=#1f2335"

      # set-option -g window-status-format "#[fg=#545c7e]#{window_index}/#{pane_current_command}:#{window_name} "
      # set-option -g window-status-current-format "#[fg=#545c7e]#{window_index}/#[fg=#E9E9EA]#{pane_current_command}:#{window_name} "

      # set-option -g window-status-current-style "fg=#E9E9EA"
      # set-option -g window-status-activity-style none

      # set-option -g pane-active-border-style "fg=#1f2335"
      # set-option -g pane-border-style "fg=#1f2335"

      #--------------------------------------------------------------------------
      # Key Bindings
      #--------------------------------------------------------------------------

      # -r means that the bind can repeat without entering prefix again
      # -n means that the bind doesn't use the prefix

      # Set the prefix to Ctrl+Space
      set -g prefix C-Space

      # Send prefix to a nested tmux session by doubling the prefix
      bind C-Space send-prefix

      # 'PREFIX r' to reload of the config file
      unbind r
      bind r source-file ~/.tmux.conf\; display-message '~/.tmux.conf reloaded'

      # Allow holding Ctrl when using using prefix+p/n for switching windows
      bind C-p previous-window
      bind C-n next-window

      # Move around in terminal
      bind-key -n Home send Escape "OH"
      bind-key -n End send Escape "OF"

      # Move around panes like in vim
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R
      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+

      # Smart pane switching with awareness of vim splits
      is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

      # Switch between previous and next windows with repeatable
      bind -r n next-window
      bind -r p previous-window

      # Move the current window to the next window or previous window position
      bind -r N run-shell "tmux swap-window -t $(expr $(tmux list-windows | grep \"(active)\" | cut -d \":\" -f 1) + 1)"
      bind -r P run-shell "tmux swap-window -t $(expr $(tmux list-windows | grep \"(active)\" | cut -d \":\" -f 1) - 1)"

      bind-key > swap-window -t +1 \; next
      bind-key < swap-window -t -1 \; prev

      # Switch between two most recently used windows
      bind Space last-window

      # Switch between two most recently used sessions
      bind ^ switch-client -l

      # use PREFIX+| (or PREFIX+\) to split window horizontally and PREFIX+- or
      # (PREFIX+_) to split vertically also use the current pane path to define the
      # new pane path
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Change the path for newly created windows
      bind c new-window -c "#{pane_current_path}"

      # Setup 'v' to begin selection as in Vim
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection -x

      bind y run -b "tmux show-buffer | xclip -selection clipboard"\; display-message "Copied tmux buffer to system clipboard"

      bind-key -r F new-window tmuxinator

      bind-key "T" run-shell "tmuxinator start \"$(
        tmuxinator list -n | tail -n +2 | fzf-tmux -p 55%,60% \
          --no-sort --border-label ' tmuxinator ' --prompt '⚡  ' \
          --header ' ^d tmux kill' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
      )\""
    '';
  };
}
