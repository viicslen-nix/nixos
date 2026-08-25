{
  flake.modules.homeManager.zsh = {
    lib,
    pkgs,
    config,
    inputs,
    ...
  }:
    with lib;
    with inputs.self.lib; let
      name = "zsh";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
      };

      config = mkIf cfg.enable (mkMerge [
        {
          programs = {
            zsh = {
              enable = true;
              autosuggestion.enable = true;
              syntaxHighlighting.enable = true;

              plugins = [
                {
                  name = "fzf-tab";
                  src = inputs.fzf-tab;
                  file = "fzf-tab.plugin.zsh";
                }
                {
                  name = "laravel-sail";
                  src = inputs.laravel-sail;
                  file = "laravel-sail.plugin.zsh";
                }
              ];

              oh-my-zsh = {
                enable = true;
                plugins = [
                  "history"
                  "git"
                  "gh"
                  "npm"
                  "node"
                  "helm"
                  "kubectl"
                  "composer"
                  "1password"
                  "docker"
                  "docker-compose"
                  "laravel"
                  "zoxide"
                  "zsh-interactive-cd"
                ];
              };
            };

            atuin.enableZshIntegration = true;
            keychain.enableZshIntegration = true;
            direnv.enableZshIntegration = true;
            carapace.enableZshIntegration = true;
            zoxide.enableZshIntegration = true;
            yazi.enableZshIntegration = true;
          };
        }
        (persistence.mkPersistence config {
          files = [".zsh_history"];
        })
      ]);
    };
}
