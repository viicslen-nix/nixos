{
  lib,
  pkgs,
  users,
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
    home-manager.users =
      lib.attrsets.mapAttrs' (name: value: (nameValuePair name {
        programs.ssh.matchBlocks = {
          "FmTod" = {
            hostname = "webapps";
            user = "fmtod";
          };

          "SellDiam" = {
            hostname = "webapps";
            user = "inventory";
          };

          "DOS" = {
            hostname = "storesites";
            user = "dostov";
          };

          "BLVD" = {
            hostname = "storesites";
            user = "diamondblvd";
          };

          "EXB" = {
            hostname = "storesites";
            user = "extrabrilliant";
          };

          "DTC" = {
            hostname = "storesites";
            user = "diamondtraces";
          };

          "NFC" = {
            hostname = "storesites";
            user = "naturalfacet";
          };

          "TJD" = {
            hostname = "storesites";
            user = "tiffanyjonesdesigns";
          };

          "47DD" = {
            hostname = "storesites";
            user = "47diamonddistrict";
          };

          "PELA" = {
            hostname = "storesites";
            user = "pelagrino";
          };
        };
      }))
      users;

    modules = {
      programs = {
        corepack.enable = true;

        mkcert = {
          enable = true;
          rootCA.enable = false;
        };
      };

      containers = {
        mysql = true;
        redis = true;
        soketi = true;
        meilisearch = true;
        qdrant.enable = true;
        buggregator.enable = true;
        nginx-proxy-manager = true;
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
      # Formatters
      delta
      jq

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
      nodejs_20
      bun
      go
      gosec

      # Tools
      mysql80
      awscli
      meld
      kubectl
      kubernetes-helm
      linode-cli
      atlas
      devbox
      act
      inputs.worktree-manager.default
      percona-toolkit
      local.app-images.responsively
      # local.mago

      # AI
      github-copilot-cli
      claude-code
      gemini-cli
    ];
  };
}
