{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "vscode";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhsWithPackages (ps:
        with ps; [
          php84
          php84Packages.composer
          nodePackages.nodejs
          corepack
          zlib
          openssl.dev
          pkg-config
        ]);
    };
  };
}
