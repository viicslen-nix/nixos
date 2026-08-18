{
  flake.modules.nixos.gaming = {
    lib,
    config,
    inputs,
    nixosModules,
    options,
    pkgs,
    users,
    ...
  }:
    with lib;
    with inputs.self.lib; let
      cfg = config.modules.functionality.gaming;
      audioQuantum = "${toString cfg.audio.quantum}/${toString cfg.audio.rate}";
      jovianPkgs = inputs.jovian.legacyPackages.x86_64-linux;
      gamescopePortalPackages = [
        jovianPkgs.xdg-desktop-portal-holo
        jovianPkgs.xdg-desktop-portal-gamescope
      ];
      gamescopePortals = pkgs.symlinkJoin {
        name = "gamescope-portals";
        paths = gamescopePortalPackages;
      };
      gamescopeSessionExports = concatStringsSep "\n" (
        mapAttrsToList (
          name: value: "export ${escapeShellArg "${name}=${value}"}"
        )
        config.programs.steam.gamescopeSession.env
      );
      steamGamescope = pkgs.writeShellApplication {
        name = "steam-gamescope";
        runtimeInputs = [
          config.programs.steam.package
          pkgs.dbus
          pkgs.systemd
        ];
        text = ''
          previous_current_desktop="''${XDG_CURRENT_DESKTOP-}"
          previous_session_desktop="''${XDG_SESSION_DESKTOP-}"
          previous_portal_dir="''${XDG_DESKTOP_PORTAL_DIR-}"

          ${gamescopeSessionExports}
          export XDG_CURRENT_DESKTOP=gamescope
          export XDG_SESSION_DESKTOP=gamescope
          export XDG_DESKTOP_PORTAL_DIR=${gamescopePortals}/share/xdg-desktop-portal/gamescope-portals

          cleanup() {
            export XDG_CURRENT_DESKTOP="$previous_current_desktop"
            export XDG_SESSION_DESKTOP="$previous_session_desktop"
            dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP || true
            if [[ -n "$previous_portal_dir" ]]; then
              systemctl --user set-environment "XDG_DESKTOP_PORTAL_DIR=$previous_portal_dir" || true
            else
              systemctl --user unset-environment XDG_DESKTOP_PORTAL_DIR || true
            fi
            systemctl --user stop xdg-desktop-portal.service || true
          }
          trap cleanup EXIT

          dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP
          systemctl --user set-environment "XDG_DESKTOP_PORTAL_DIR=$XDG_DESKTOP_PORTAL_DIR"
          systemctl --user stop xdg-desktop-portal.service
          gamescope --steam ${escapeShellArgs config.programs.steam.gamescopeSession.args} -- \
            steam ${escapeShellArgs config.programs.steam.gamescopeSession.steamArgs}
        '';
      };
      steamGamescopeSession =
        (pkgs.writeTextDir "share/wayland-sessions/steam.desktop" ''
          [Desktop Entry]
          Name=Steam
          Comment=A Gamescope-driven Steam session
          Exec=${steamGamescope}/bin/steam-gamescope
          Type=Application
        '').overrideAttrs (_: {
          passthru.providedSessions = ["steam"];
        });
    in {
      imports = [
        "${inputs.jovian}/modules/decky-loader.nix"
        nixosModules.programs.steam
      ];

      options.modules.functionality.gaming = {
        enable = mkEnabledOption (mdDoc "gaming support");

        extraPackages = mkOption {
          type = types.listOf types.package;
          default = [];
          description = "Additional gaming packages to install";
        };

        steam = {
          enable = mkEnabledOption "Steam";
          protonGe = mkEnabledOption "GE-Proton";
          protontricks = mkEnabledOption "Protontricks";
          gamescopeSession = mkEnabledOption "the dedicated Steam Gamescope session";
          extest = mkEnableOption "the Steam Input Wayland mouse workaround";
          remotePlay.openFirewall = mkEnableOption "Steam Remote Play firewall ports";
          localNetworkTransfers.openFirewall = mkEnableOption "Steam LAN transfer firewall ports";
          dedicatedServer.openFirewall = mkEnableOption "Source dedicated-server firewall ports";
        };

        launchers = {
          bottles = mkEnabledOption "Bottles";
          heroic = mkEnabledOption "Heroic Games Launcher";
          lutris = mkEnabledOption "Lutris";
        };

        wine = {
          enable = mkEnabledOption "Wine support";
          package = mkOption {
            type = types.package;
            default = pkgs.wineWow64Packages.stable;
            defaultText = literalExpression "pkgs.wineWow64Packages.stable";
            description = "Wine package to install";
          };
          winetricks = mkEnabledOption "Winetricks";
        };

        tools = {
          goverlay = mkEnabledOption "GOverlay";
          mangohud = mkEnabledOption "MangoHud";
          protonplus = mkEnabledOption "ProtonPlus";
          vkbasalt = mkEnabledOption "vkBasalt";
        };

        gamemode = {
          enable = mkEnabledOption "GameMode";
          enableRenice = mkEnableOption "GameMode process renicing with CAP_SYS_NICE";
        };

        gamescope = {
          enable = mkEnabledOption "Gamescope";
          enableWsi = mkEnableOption "the Gamescope Vulkan WSI layer";
          capSysNice = mkEnableOption "CAP_SYS_NICE for Gamescope";
        };

        deckyLoader.enable = mkEnabledOption "Decky Loader";

        zram = {
          enable = mkEnabledOption "compressed ZRAM swap";
          algorithm = mkOption {
            type = types.str;
            default = "zstd";
            description = "Compression algorithm for ZRAM swap";
          };
          memoryPercent = mkOption {
            type = types.ints.between 1 100;
            default = 50;
            description = "Percentage of RAM allocated to ZRAM swap";
          };
          priority = mkOption {
            type = types.int;
            default = 100;
            description = "ZRAM swap priority";
          };
        };

        controllers = {
          extraRules = mkEnabledOption "community udev rules for additional game controllers";
          xpadneo = mkEnableOption "Xbox Bluetooth controller support through xpadneo";
          xone = mkEnableOption "Xbox wired and wireless-dongle support through xone";
          joycond = mkEnableOption "Nintendo Joy-Con and Pro Controller support";
        };

        audio = {
          lowLatency = mkEnableOption "system-wide low-latency PipeWire settings";
          quantum = mkOption {
            type = types.ints.positive;
            default = 64;
            description = "PipeWire quantum used by the low-latency profile";
          };
          rate = mkOption {
            type = types.ints.positive;
            default = 48000;
            description = "PipeWire sample rate used by the low-latency profile";
          };
        };

        performance.platformOptimizations = mkEnableOption "SteamOS-derived kernel sysctls";
      };

      config = mkMerge [
        {
          modules.programs.steam.enable = mkDefault (cfg.enable && cfg.steam.enable);
          jovian.decky-loader.package = mkDefault jovianPkgs.decky-loader;
        }
        (mkIf cfg.enable (mkMerge [
          {
            assertions = [
              {
                assertion = pkgs.stdenv.hostPlatform.isx86_64;
                message = "modules.functionality.gaming currently supports only x86_64-linux";
              }
            ];

            hardware = {
              graphics = {
                enable = true;
                enable32Bit = true;
              };
              xpadneo.enable = cfg.controllers.xpadneo;
              xone.enable = cfg.controllers.xone;
            };

            services = {
              joycond.enable = cfg.controllers.joycond;
              udev.packages = optionals cfg.controllers.extraRules [pkgs.game-devices-udev-rules];
            };

            programs = {
              steam = mkIf cfg.steam.enable {
                extraCompatPackages = optionals cfg.steam.protonGe [pkgs.proton-ge-bin];
                protontricks.enable = cfg.steam.protontricks;
                extest.enable = cfg.steam.extest;
                remotePlay.openFirewall = cfg.steam.remotePlay.openFirewall;
                localNetworkGameTransfers.openFirewall = cfg.steam.localNetworkTransfers.openFirewall;
                dedicatedServer.openFirewall = cfg.steam.dedicatedServer.openFirewall;
              };
              gamemode = {
                enable = cfg.gamemode.enable;
                enableRenice = cfg.gamemode.enableRenice;
              };
              gamescope = {
                enable = cfg.gamescope.enable || (cfg.steam.enable && cfg.steam.gamescopeSession);
                inherit (cfg.gamescope) capSysNice enableWsi;
              };
            };

            jovian.decky-loader.enable = cfg.deckyLoader.enable;

            environment.systemPackages =
              optionals cfg.launchers.bottles [pkgs.bottles]
              ++ optionals cfg.launchers.heroic [pkgs.heroic]
              ++ optionals cfg.launchers.lutris [pkgs.lutris]
              ++ optionals cfg.tools.goverlay [pkgs.goverlay]
              ++ optionals cfg.tools.mangohud [pkgs.mangohud]
              ++ optionals cfg.tools.protonplus [pkgs.protonplus]
              ++ optionals cfg.tools.vkbasalt [pkgs.vkbasalt]
              ++ optionals cfg.wine.enable [cfg.wine.package]
              ++ optionals (cfg.wine.enable && cfg.wine.winetricks) [pkgs.winetricks]
              ++ optionals cfg.gamescope.capSysNice [config.programs.gamescope.package]
              ++ cfg.extraPackages;
          }

          (mkIf (cfg.steam.enable && cfg.steam.gamescopeSession) {
            services.displayManager.sessionPackages = [steamGamescopeSession];

            xdg.portal = {
              enable = true;
              config.gamescope.default = [
                "holo"
                "gamescope"
              ];
              extraPortals = gamescopePortalPackages;
            };
          })

          (mkIf cfg.zram.enable {
            zramSwap = {
              enable = true;
              inherit (cfg.zram) algorithm memoryPercent priority;
            };
          })

          (mkIf cfg.performance.platformOptimizations {
            boot.kernel.sysctl = {
              "kernel.sched_cfs_bandwidth_slice_us" = 3000;
              "net.ipv4.tcp_fin_timeout" = 5;
              "kernel.split_lock_mitigate" = 0;
              "vm.max_map_count" = 2147483642;
            };
          })

          (mkIf cfg.audio.lowLatency {
            security.rtkit.enable = true;
            services.pipewire = {
              enable = true;
              wireplumber.enable = true;
              extraConfig = {
                pipewire."99-gaming-low-latency" = {
                  "context.properties"."default.clock.min-quantum" = cfg.audio.quantum;
                  "context.modules" = [
                    {
                      name = "libpipewire-module-rt";
                      flags = [
                        "ifexists"
                        "nofail"
                      ];
                      args = {
                        "nice.level" = -15;
                        "rt.prio" = 88;
                        "rt.time.soft" = 200000;
                        "rt.time.hard" = 200000;
                      };
                    }
                  ];
                };
                pipewire-pulse."99-gaming-low-latency"."pulse.properties" = {
                  "server.address" = ["unix:native"];
                  "pulse.min.req" = audioQuantum;
                  "pulse.min.quantum" = audioQuantum;
                  "pulse.min.frag" = audioQuantum;
                };
                client."99-gaming-low-latency"."stream.properties" = {
                  "node.latency" = audioQuantum;
                  "resample.quality" = 1;
                };
              };
            };
          })

          (persistence.mkHmPersistence {
            inherit config options;
            users = attrNames users;
            directories = optionals cfg.wine.enable [".wine"];
            configDirs =
              optionals cfg.tools.goverlay ["goverlay"]
              ++ optionals cfg.tools.mangohud ["MangoHud"]
              ++ optionals cfg.tools.protonplus ["ProtonPlus"]
              ++ optionals cfg.tools.vkbasalt ["vkBasalt"]
              ++ optionals cfg.launchers.heroic ["heroic"]
              ++ optionals cfg.launchers.lutris ["lutris"];
            share =
              optionals cfg.launchers.bottles ["bottles"]
              ++ optionals cfg.launchers.lutris ["lutris"];
          })

          (persistence.mkNixosPersistence {
            inherit config;
            directories = optionals cfg.deckyLoader.enable [
              (toString config.jovian.decky-loader.stateDir)
            ];
          })
        ]))
      ];
    };
}
