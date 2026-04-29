{
  lib,
  pkgs,
  users,
  config,
  inputs,
  ...
}:
with lib; {
  imports = [inputs.opencode.nixosModules.opencode-web];
  config = {
    home-manager.sharedModules = [./home.nix];

    modules = {
      services.opencode-web.enable = true;

      programs = {
        corepack.enable = true;
        mkcert.enable = true;
      };

      containers = {
        traefik.enable = true;
        mysql.enable = true;
        redis.enable = true;
        soketi.enable = true;
        qdrant.enable = true;
        centrifugo.enable = true;
        meilisearch.enable = true;
        buggregator.enable = true;
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
      pkg-config
      opusTools
      opusfile
      opustags

      # Tools
      gh
      glab
      awscli
      meld
      kubectl
      kubernetes-helm
      linode-cli
      atlas
      devbox
      act
      github-desktop
      gh-dash
      # pkgs.inputs.gitura.default
      pkgs.inputs.ghost-backup.default
      percona-toolkit
      pkgs.inputs.packages.app-images.responsively
      pkgs.inputs.packages.coderabbit
      # pkgs.inputs.packages.mago

      # AI
      unstable.github-copilot-cli
      unstable.gemini-cli
      pkgs.inputs.packages.openwork
    ];
  };
}
