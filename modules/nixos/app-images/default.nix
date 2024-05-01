{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.features.appImages;
in {
  options.features.appImages = {
    enable = mkEnableOption (mdDoc "app-images");
  };

  config = mkIf cfg.enable {
    boot.binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
  };
}
