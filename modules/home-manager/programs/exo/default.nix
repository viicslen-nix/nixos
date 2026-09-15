{
  flake.modules.homeManager.exo = {
    lib,
    pkgs,
    config,
    options,
    inputs,
    osConfig ? {},
    ...
  }:
    with lib; let
      name = "exo";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      ignis = getExe config.programs.ignis.finalPackage;

      # Exo's own matugen config writes ten templates across $HOME and pkills kitty;
      # this one emits only the stylesheet, so seeding cannot touch anything else.
      seedConfig = pkgs.writeText "matugen-seed.toml" ''
        [config]

        [templates.ignis]
        input_path = '${inputs.exo}/matugen/templates/colors.scss'
        output_path = '~/.config/ignis/colors.scss'
      '';

      defaultColors = pkgs.runCommand "exo-colors.scss" {} ''
        export HOME="$(mktemp -d)"
        # --prefer: matugen refuses to choose between multiple source colors off a terminal.
        ${getExe pkgs.matugen} -c ${seedConfig} --prefer saturation \
          image ${inputs.exo}/exodefaults/default_wallpaper.png
        cp "$HOME/.config/ignis/colors.scss" "$out"
      '';
    in {
      imports = [inputs.ignis.homeManagerModules.default];

      options.modules.${namespace}.${name} = {
        enable = mkOption {
          type = types.bool;
          default = (osConfig.modules.desktop.shell or null) == name;
          defaultText = literalExpression "config.modules.desktop.shell == \"exo\"";
          description = mdDoc "Whether to enable the ${name} desktop shell.";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          programs.ignis = {
            enable = true;

            services = {
              audio.enable = true;
              network.enable = true;
              bluetooth.enable = true;
              recorder.enable = true;
            };

            sass = {
              enable = true;
              useDartSass = true;
            };
          };

          # Not `programs.ignis.configDir` — that links the directory itself, and
          # Exo writes user_settings.json and matugen's colors.scss inside it.
          xdg.configFile."ignis" = {
            source = inputs.exo + "/ignis";
            recursive = true;
          };

          xdg.configFile."matugen" = {
            source = inputs.exo + "/matugen";
            recursive = true;
          };

          home.packages = with pkgs; [
            matugen
            awww
            # matugen/config.toml calls `swww`, the name nixpkgs renamed to `awww`.
            (writeShellScriptBin "swww" ''exec ${getExe pkgs.awww} "$@"'')
            adw-gtk3
            gnome-bluetooth
            material-symbols
            gpu-screen-recorder
            slurp
          ];

          # Ignis opens user_settings.json unconditionally and the styles `@use
          # "../colors"`, but Exo ships neither — its installer generates both on
          # first run. Seed them once, never overwrite: these are Exo's own state.
          home.activation.exoBootstrap = hm.dag.entryAfter ["writeBoundary"] ''
            cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/ignis"
            run mkdir -p "$cfg"

            if [ ! -e "$cfg/user_settings.json" ]; then
              run install -m644 ${pkgs.writeText "user_settings.json" "{}"} "$cfg/user_settings.json"
            fi

            if [ ! -e "$cfg/preview-colors.scss" ]; then
              run install -m644 ${inputs.exo}/exodefaults/preview-colors.scss "$cfg/preview-colors.scss"
            fi

            if [ ! -e "$cfg/colors.scss" ]; then
              run install -m644 ${defaultColors} "$cfg/colors.scss"
            fi
          '';

          systemd.user.services.exo = {
            Unit = {
              Description = "Exo desktop shell";
              PartOf = ["desktop-shell.target"];
              After = ["desktop-shell.target" "swww.service"];
            };

            Service = {
              Type = "exec";
              ExecStart = "${ignis} init";
              Restart = "on-failure";
              RestartSec = "5s";
              Slice = "session.slice";
            };

            Install.WantedBy = ["desktop-shell.target"];
          };

          # Exo sets wallpapers through swww, so the daemon has to be up first.
          systemd.user.services.swww = {
            Unit = {
              Description = "swww wallpaper daemon";
              PartOf = ["desktop-shell.target"];
            };

            Service = {
              Type = "exec";
              ExecStart = getExe' pkgs.awww "awww-daemon";
              Restart = "on-failure";
              RestartSec = "5s";
              Slice = "session.slice";
            };

            Install.WantedBy = ["desktop-shell.target"];
          };
        }

        # The shell owns its own binds; niri never learns which shell is running.
        (mkIf (options.programs ? niri) {
          programs.niri.settings.binds = with config.lib.niri.actions; {
            "Mod+Space" = {
              repeat = false;
              action = spawn ignis "toggle-window" "Launcher";
            };
            "Mod+G".action = spawn ignis "toggle-window" "QuickCenter";
            "Mod+Shift+Q".action = spawn ignis "toggle-window" "PowerMenu";
            "Mod+Shift+N".action = spawn ignis "toggle-window" "Settings";
          };
        })
      ]);
    };
}
