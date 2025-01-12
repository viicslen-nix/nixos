{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "work";
  namespace = "presets";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    modules = {
      functionality.network.hosts = {
        # Docker
        "kubernetes.docker.internal" = "127.0.0.1";
        "host.docker.internal" = "127.0.0.1";

        # Remote
        "webapps" = "REDACTED";
        "storesites" = "REDACTED";

        # Development
        "ai.local" = "127.0.0.1";
        "home.local" = "127.0.0.1";
        "buggregator.local" = "127.0.0.1";
        "npm.local" = "127.0.0.1";
        "portainer.local" = "127.0.0.1";
        "phpmyadmin.local" = "127.0.0.1";
        "selldiam.test" = "127.0.0.1";
        "mylisterhub.test" = "127.0.0.1";
        "app.mylisterhub.test" = "127.0.0.1";
        "admin.mylisterhub.test" = "127.0.0.1";
        "*.mylisterhub.test" = "127.0.0.1";
      };

      programs = {
        corepack.enable = true;

        docker = {
          enable = true;
          allowTcpPorts = [
            # Traefik
            80
            443
            8080

            # PHPStorm Xdebug
            9003

            # Portainer
            9443

            # MySQL
            3306

            # Ray
            23517
          ];
        };

        mkcert = {
          enable = true;
          rootCA.enable = false;
        };
      };

      containers = {
        portainer = true;
        mysql = true;
        redis = true;
        soketi = true;
        buggregator.enable = true;
        meilisearch = true;
        nginx-proxy-manager = true;
        local-ai = true;
      };
    };

    programs.zsh.shellAliases = {
      dep = "composer exec -- dep";
      takeout = "composer global exec -- takeout";
      nix-dev = "nix develop path:.";
    };

    environment.systemPackages = with pkgs; let
      phpWithExtensions = php.buildEnv {
        extensions = {
          enabled,
          all,
        }:
          enabled
          ++ (with all; [
            xdebug
            imagick
            redis
          ]);
        extraConfig = ''
          memory_limit=-1
          max_execution_time=0
        '';
      };
    in [
      # Communication
      slack

      # Formatters
      delta
      jq

      # Editors
      jetbrains-toolbox
      jetbrains.idea-ultimate
      jetbrains.phpstorm
      jetbrains.datagrip
      jetbrains.webstorm
      jetbrains.goland
      vscode

      # Build
      libgcc
      gcc13
      gcc
      zig
      bc
      gnumake
      cmake
      luakit
      phpWithExtensions
      phpWithExtensions.packages.composer

      # Tools
      nodejs_20
      mysql80
      awscli
      meld
      kubectl
      kubernetes-helm
      linode-cli
      dbeaver-bin
      atlas
      sublime-merge
      devbox
      act
    ];
  };
}
