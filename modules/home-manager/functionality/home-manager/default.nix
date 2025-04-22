{
  lib,
  config,
  osConfig,
  ...
}:
with lib; let
  name = "home-manager";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    overrideBackups = mkEnableOption (mdDoc ''
      Whether to overwrite the backup files created by home-manager.
    '');
  };

  config = {
    home.activation.hmOverrideBackupFiles = mkIf cfg.overrideBackups (lib.hm.dag.entryBefore ["writeBoundary"] ''
      find ${config.home.homeDirectory} -type f -name "*.${osConfig.home-manager.backupFileExtension}" 2>/dev/null | while read -r backupFile; do
        originalFile="''${backupFile%.${osConfig.home-manager.backupFileExtension}}"
        if [ -f "$originalFile" ]; then
          rm -f "$backupFile"
        fi
      done
    '');
  };
}
