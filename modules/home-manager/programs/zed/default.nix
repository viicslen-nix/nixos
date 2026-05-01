{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "zed";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.zed-editor = {
        enable = true;
        enableMcpIntegration = true;
        mutableUserKeymaps = false;
        mutableUserSettings = false;
        userSettings = mkForce (
          let
            baseSettings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./settings.json));
          in
            recursiveUpdate baseSettings {
              languages.PHP.language_servers = [
                "phpantom_lsp"
                "!intelephense"
                "!phpactor"
                "!phptools"
                "..."
              ];
            }
        );
        extraPackages = with pkgs; [
          pkgs.inputs.packages.php.phpantom-lsp
          rustc
          cargo
          cargo-wasi
          rustup
        ];
      };
        xdg.dataFile."zed/dev-extensions/phpantom_lsp".source = inputs.phpantom-lsp-src + "/zed-extension";
    }
    (persistence.mkPersistence config {
      config = ["Zed"];
    })
  ]);
}
