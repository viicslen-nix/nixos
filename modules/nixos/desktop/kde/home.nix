{
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  programs.plasma = {
    enable = true;

    hotkeys.commands."1password-quick-access" = {
      name = "1Password Quick Access";
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
      "kded5rc"."Module-device_automounter"."autoload" = false;
      "kwinrc"."Desktops"."Number" = 1;
      "kwinrc"."Desktops"."Rows" = 1;
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
