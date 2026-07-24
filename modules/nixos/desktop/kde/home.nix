{
  lib,
  config,
  ...
}: let
  # Reuse the shared defaults so KDE launchers match the niri binds
  defaults = config.modules.functionality.defaults;

  appHotkey = slug: key: name: pkg:
    lib.optionalAttrs (pkg != null) {
      ${slug} = {
        inherit name key;
        command = lib.getExe pkg;
      };
    };
in {
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  programs.plasma = {
    enable = true;

    # Match niri's 10 workspaces (Meta+1..0)
    kwin.virtualDesktops = {
      number = 10;
      rows = 1;
    };

    hotkeys.commands =
      {
        "1password-quick-access" = {
          name = "1Password Quick Access";
          key = "Ctrl+Shift+Space";
          command = "1password --quick-access";
        };
      }
      // appHotkey "launch-terminal" "Meta+Return" "Launch Terminal" defaults.terminal
      // appHotkey "launch-browser" "Meta+B" "Launch Browser" defaults.browser
      // appHotkey "launch-file-manager" "Meta+E" "Launch File Manager" defaults.fileManager;

    # KWin equivalents of the niri binds. Scrollable "columns" map to KWin
    # window focus; niri workspaces map to KDE virtual desktops.
    # ponytail: which-key menus (Mod+W/Z/A, screenshot/record) have no KWin
    # equivalent and are dropped; Mod+T floating toggle has no stable action name.
    shortcuts.kwin = {
      "Window Close" = "Meta+Q";
      "Window Maximize" = "Meta+F";
      "Window Fullscreen" = "Meta+Shift+F";

      # Focus movement (vim keys + arrows)
      "Switch Window Left" = ["Meta+H" "Meta+Left"];
      "Switch Window Right" = ["Meta+L" "Meta+Right"];
      "Switch Window Up" = "Meta+K";
      "Switch Window Down" = "Meta+J";
      "Walk Through Windows" = "Meta+Tab";
      "Walk Through Windows (Reverse)" = "Meta+Shift+Tab";

      # Workspace (virtual desktop) switching
      "Switch to Next Desktop" = ["Meta+Ctrl+H" "Meta+Down"];
      "Switch to Previous Desktop" = ["Meta+Ctrl+L" "Meta+Up"];
      "Switch to Desktop 1" = "Meta+1";
      "Switch to Desktop 2" = "Meta+2";
      "Switch to Desktop 3" = "Meta+3";
      "Switch to Desktop 4" = "Meta+4";
      "Switch to Desktop 5" = "Meta+5";
      "Switch to Desktop 6" = "Meta+6";
      "Switch to Desktop 7" = "Meta+7";
      "Switch to Desktop 8" = "Meta+8";
      "Switch to Desktop 9" = "Meta+9";
      "Switch to Desktop 10" = "Meta+0";

      # Move window to workspace
      "Window to Desktop 1" = "Meta+Shift+1";
      "Window to Desktop 2" = "Meta+Shift+2";
      "Window to Desktop 3" = "Meta+Shift+3";
      "Window to Desktop 4" = "Meta+Shift+4";
      "Window to Desktop 5" = "Meta+Shift+5";
      "Window to Desktop 6" = "Meta+Shift+6";
      "Window to Desktop 7" = "Meta+Shift+7";
      "Window to Desktop 8" = "Meta+Shift+8";
      "Window to Desktop 9" = "Meta+Shift+9";
      "Window to Desktop 10" = "Meta+Shift+0";

      # Monitor focus / move window to monitor
      "Switch to Screen to the Left" = ["Meta+Shift+H" "Meta+Shift+Left"];
      "Switch to Screen to the Right" = ["Meta+Shift+L" "Meta+Shift+Right"];
      "Window to Previous Screen" = ["Meta+Shift+Alt+H" "Meta+Shift+Alt+Left"];
      "Window to Next Screen" = ["Meta+Shift+Alt+L" "Meta+Shift+Alt+Right"];
    };

    configFile = {
      "baloofilerc"."General"."dbVersion" = 2;
      "baloofilerc"."General"."exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
      "baloofilerc"."General"."exclude filters version" = 9;
      "dolphinrc"."General"."ViewPropsTimestamp" = "2025,3,15,22,31,8.444";
      "dolphinrc"."KFileDialog Settings"."Places Icons Auto-resize" = false;
      "dolphinrc"."KFileDialog Settings"."Places Icons Static Size" = 22;
      "kactivitymanagerdrc"."Plugins"."org.kde.ActivityManager.ResourceScoringEnabled" = false;
      "kactivitymanagerdrc"."activities"."ef99cca3-daa1-42a3-b4c3-19467353dcbf" = "Default";
      "kactivitymanagerdrc"."main"."currentActivity" = "ef99cca3-daa1-42a3-b4c3-19467353dcbf";
      "kded5rc"."Module-device_automounter"."autoload" = false;
      "kwinrc"."Effect-translucency"."Inactive" = 90;
      "kwinrc"."Plugins"."dimscreenEnabled" = true;
      "kwinrc"."Plugins"."hidecursorEnabled" = true;
      "kwinrc"."Plugins"."wobblywindowsEnabled" = true;
      "kwinrc"."Tiling"."padding" = 4;
      "kwinrc"."Windows"."FocusPolicy" = "FocusFollowsMouse";
      "kwinrc"."Windows"."NextFocusPrefersMouse" = true;
      "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
      "systemsettingsrc"."systemsettings_sidebar_mode"."HighlightNonDefaultSettings" = true;
    };
  };
}
