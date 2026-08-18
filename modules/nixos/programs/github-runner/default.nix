{
  flake.modules.nixos.github-runner = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "github-runner";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        url = mkOption {
          type = types.str;
          description = ''
            The URL of the repository to run the GitHub runner for.
          '';
        };

        secrets = {
          token = mkOption {
            type = types.path;
            description = ''
              The path to the age encrypted token file.
            '';
          };
        };
      };

      config = mkIf cfg.enable {
        # age.secrets."github-runners/nixos.token".file = cfg.secrets.token;

        services.github-runners.${config.networking.hostName} = {
          enable = true;
          replace = true;
          ephemeral = true;
          user = "root";
          inherit (cfg) url;
          # tokenFile = config.age.secrets."github-runners/nixos.token".path;
          extraPackages = with pkgs; [
            sudo
            bash
            git
            gh
            docker
            qemu
          ];
        };
      };
    };
}
