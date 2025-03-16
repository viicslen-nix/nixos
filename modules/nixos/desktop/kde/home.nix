{
  programs.plasma = {
    enable = true;

    hotkeys.commands."launch-1password" = {
      name = "Launch Konsole";
      key = "Ctrl+Shift+Space";
      command = "1password --quick-access";
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
      "kcminputrc"."Mouse"."cursorTheme" = "breeze_cursors";
      "kded5rc"."Module-device_automounter"."autoload" = false;
      "kdeglobals"."General"."TerminalApplication" = "kitty";
      "kdeglobals"."General"."TerminalService" = "kitty.desktop";
      "kdeglobals"."Icons"."Theme" = "Fluent-dark";
      "kdeglobals"."WM"."activeBackground" = "33,33,33";
      "kdeglobals"."WM"."activeBlend" = "255,203,107";
      "kdeglobals"."WM"."activeForeground" = "238,255,255";
      "kdeglobals"."WM"."inactiveBackground" = "33,33,33";
      "kdeglobals"."WM"."inactiveBlend" = "74,74,74";
      "kdeglobals"."WM"."inactiveForeground" = "238,255,255";
      "ksplashrc"."KSplash"."Theme" = "a2n.kuro";
      "kwalletrc"."Wallet"."Close When Idle" = false;
      "kwalletrc"."Wallet"."Close on Screensaver" = false;
      "kwalletrc"."Wallet"."Default Wallet" = "kdewallet";
      "kwalletrc"."Wallet"."Enabled" = true;
      "kwalletrc"."Wallet"."First Use" = false;
      "kwalletrc"."Wallet"."Idle Timeout" = 10;
      "kwalletrc"."Wallet"."Launch Manager" = true;
      "kwalletrc"."Wallet"."Leave Manager Open" = false;
      "kwalletrc"."Wallet"."Leave Open" = true;
      "kwalletrc"."Wallet"."Prompt on Open" = false;
      "kwalletrc"."Wallet"."Use One Wallet" = true;
      "kwalletrc"."org.freedesktop.secrets"."apiEnabled" = true;
      "kwinrc"."Desktops"."Id_1" = "3668203b-225f-4a09-a851-1a66019056f5";
      "kwinrc"."Desktops"."Number" = 1;
      "kwinrc"."Desktops"."Rows" = 1;
      "kwinrc"."Effect-translucency"."Inactive" = 89;
      "kwinrc"."Plugins"."dimscreenEnabled" = true;
      "kwinrc"."Plugins"."hidecursorEnabled" = true;
      "kwinrc"."Plugins"."wobblywindowsEnabled" = true;
      "kwinrc"."Tiling"."padding" = 4;
      "kwinrc"."Tiling/0be159e5-8df9-555b-8a92-862e49e2f0f6"."tiles" = "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
      "kwinrc"."Windows"."FocusPolicy" = "FocusFollowsMouse";
      "kwinrc"."Windows"."NextFocusPrefersMouse" = true;
      "kwinrc"."Xwayland"."Scale" = 1.5;
      "kwinrc"."org.kde.kdecoration2"."theme" = "__aurorae__svg__WillowDarkBlurAlt";
      "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
      "systemsettingsrc"."systemsettings_sidebar_mode"."HighlightNonDefaultSettings" = true;
    };
  };
}
