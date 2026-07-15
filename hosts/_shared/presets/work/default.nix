{
  lib,
  pkgs,
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
      nodejs_22
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
      percona-toolkit
      ferdium
      sublime4
      sublime-merge
      pkgs.inputs.hunk.hunk
      # pkgs.inputs.gitura.default
      pkgs.inputs.ghost-backup.default
      pkgs.inputs.packages.app-images.responsively

      # AI
      pkgs.inputs.packages.coderabbit
      pkgs.inputs.packages.app-images.t3code
      pkgs.inputs.packages.superset.desktop
      pkgs.inputs.packages.superset.cli
      pkgs.inputs.packages.github.copilot-desktop
      pkgs.inputs.llm-agents.claude-desktop
    ];

    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];

    # sublimetext4 is marked broken because its plug-in host needs the insecure
    # OpenSSL above, which we already permit. Downgrade the block to a warning.
    nixpkgs.config.problems.handlers.sublimetext4.broken = "warn";
  };
}
