{
  flake.modules.homeManager.wezterm = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "wezterm";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        leader = mkOption {
          type = types.attrs;
          default = {
            key = ";";
            mods = "CTRL";
            timeout_milliseconds = 1000;
          };
          description = mdDoc ''
            Leader key for the wezterm-native pane bindings. Kept off tmux's
            `C-Space` prefix and off readline, so both multiplexers coexist.
          '';
        };
      };

      config = mkIf cfg.enable {
        programs.wezterm = {
          enable = true;

          enableZshIntegration = true;

          # ponytail: the pinned home-manager has no `settings` option, so the
          # whole config is Lua. `wezterm` is already in scope.
          extraConfig = ''
            local act = wezterm.action

            -- Move, then stay in the nav table so h/j/k/l repeat without the
            -- leader -- the equivalent of tmux's `bind -r`.
            local function nav(dir)
              return act.Multiple {
                act.ActivatePaneDirection(dir),
                act.ActivateKeyTable {
                  name = 'pane_nav',
                  one_shot = false,
                  timeout_milliseconds = 1000,
                },
              }
            end

            local toggle_decorations = wezterm.action_callback(function(window)
              local overrides = window:get_config_overrides() or {}
              if overrides.window_decorations == 'TITLE|RESIZE' then
                overrides.window_decorations = 'RESIZE'
              else
                overrides.window_decorations = 'TITLE|RESIZE'
              end
              window:set_config_overrides(overrides)
            end)

            return {
              -- Account shell is zsh (Superset wraps it); nu stays the
              -- interactive shell here.
              default_prog = { '${lib.getExe pkgs.nushell}' },

              font_size = 11.0,
              line_height = 1.25,

              window_background_opacity = 0.8,
              wayland_window_background_blur = true,

              window_decorations = 'RESIZE',
              -- tmux owns windows; wezterm's bar would only duplicate them.
              enable_tab_bar = false,

              check_for_updates = false,
              window_close_confirmation = 'AlwaysPrompt',

              leader = ${generators.toLua {} cfg.leader},

              keys = {
                -- Splits, same mnemonics as tmux.conf.
                { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
                { key = '-', mods = 'LEADER',       action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

                { key = 'q', mods = 'LEADER',     action = act.CloseCurrentPane { confirm = true } },
                { key = 'q', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },

                -- Double the leader to pass it to the program inside, like
                -- tmux's `bind C-Space send-prefix`.
                { key = '${cfg.leader.key}', mods = 'LEADER|${cfg.leader.mods}', action = act.SendKey { key = '${cfg.leader.key}', mods = '${cfg.leader.mods}' } },

                { key = 'Enter', mods = 'SHIFT',     action = act.SendString '\x1b\r' },
                { key = 'w',     mods = 'CTRL|SHIFT', action = toggle_decorations },

                { key = 'h',          mods = 'LEADER', action = nav 'Left'  },
                { key = 'j',          mods = 'LEADER', action = nav 'Down'  },
                { key = 'k',          mods = 'LEADER', action = nav 'Up'    },
                { key = 'l',          mods = 'LEADER', action = nav 'Right' },
                { key = 'LeftArrow',  mods = 'LEADER', action = nav 'Left'  },
                { key = 'DownArrow',  mods = 'LEADER', action = nav 'Down'  },
                { key = 'UpArrow',    mods = 'LEADER', action = nav 'Up'    },
                { key = 'RightArrow', mods = 'LEADER', action = nav 'Right' },
              },

              key_tables = {
                pane_nav = {
                  { key = 'h',          action = act.ActivatePaneDirection 'Left'  },
                  { key = 'j',          action = act.ActivatePaneDirection 'Down'  },
                  { key = 'k',          action = act.ActivatePaneDirection 'Up'    },
                  { key = 'l',          action = act.ActivatePaneDirection 'Right' },
                  { key = 'LeftArrow',  action = act.ActivatePaneDirection 'Left'  },
                  { key = 'DownArrow',  action = act.ActivatePaneDirection 'Down'  },
                  { key = 'UpArrow',    action = act.ActivatePaneDirection 'Up'    },
                  { key = 'RightArrow', action = act.ActivatePaneDirection 'Right' },
                  { key = 'Escape',     action = act.PopKeyTable },
                },
              },
            }
          '';
        };

        dconf.settings."org/gnome/shell/extensions/blur-my-shell/applications" = {
          whitelist = ["org.wezfurlong.wezterm"];
        };
      };
    };
}
