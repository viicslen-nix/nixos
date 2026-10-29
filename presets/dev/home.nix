{
  lib,
  pkgs,
  config,
  inputs,
  osConfig,
  homeModules,
  ...
}: let
  desktop = osConfig.modules.presets.desktop.enable;

  phpWithExtensions = pkgs.php.buildEnv {
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
in {
  imports = [
    homeModules.programs.hunk
    homeModules.programs.tinkerwell
    homeModules.programs.k9s
    homeModules.programs.krr
  ];

  age.secrets.intelephense = {
    file = ../../secrets/intelephense/licence.age;
    path = "${config.home.homeDirectory}/intelephense/licence.txt";
  };

  # mkAfter keeps it after the shared zsh module's fzf-tab.
  programs.zsh.plugins = lib.mkAfter [
    {
      name = "laravel-sail";
      src = inputs.laravel-sail;
      file = "laravel-sail.plugin.zsh";
    }
  ];

  home.shellAliases = {
    k = "kubectl";
    kga = "kubectl get all";
    kgp = "kubectl get pods";
    kdp = "kubectl describe pod";
    kcuc = "kubectl config use-context";
    krr = "kubectl rollout restart";

    dep = "vendor/bin/dep";

    sail = "vendor/bin/sail";
    s = "vendor/bin/sail";
    sud = "vendor/bin/sail up -d";
    sdown = "vendor/bin/sail down";
    art = "vendor/bin/sail artisan";
    sa = "vendor/bin/sail artisan";
    sc = "vendor/bin/sail composer";
    sp = "vendor/bin/sail php";
    sn = "vendor/bin/sail npm";
    st = "vendor/bin/sail tinker";
    sd = "vendor/bin/sail debug";
    sda = "vendor/bin/sail debug artisan";

    laravel = "composer global exec laravel --";
  };

  home.packages = with pkgs;
    [
      # Toolchains
      libgcc
      gcc13
      zig
      bc
      gnumake
      cmake
      pkg-config
      phpWithExtensions
      phpWithExtensions.packages.composer
      nodejs_22
      node-gyp
      bun
      # vite+ ("The Unified Toolchain for the Web"); binary is `vp`.
      # Not in nixpkgs — reached through omniflake's index.
      pkgs.inputs.nix-vite-plus.default
      python3
      uv
      go
      gosec
      devbox

      # Audio
      opus-tools
      opusfile
      opustags

      # Git
      lazygit
      delta
      glab
      gh-dash
      act
      unstable.but
      # pkgs.inputs.gitura.default
      pkgs.inputs.ghost-backup.default
      pkgs.inputs.tuicr.default
      pkgs.inputs.packages.scripts.git-carve-submodule

      # Nix
      nix-alien
      nix-init
      graphviz

      # Infra
      kubectl
      kubernetes-helm
      cloudflared
      wrangler
      unstable.cf
      pkgs.inputs.packages.blacksmith
      atlas
      percona-toolkit
    ]
    ++ import ./scripts.nix {inherit pkgs;}
    ++ lib.optionals desktop [
      # Editors
      # jetbrains-toolbox
      unstable.code-cursor-fhs
      pkgs.inputs.emacs.default

      # Databases & APIs
      dbeaver-bin
      insomnia
      postman
      pkgs.inputs.packages.app-images.responsively

      # Git
      gitbutler
      github-desktop
      sublime-merge

      # Infra
      lens

      # AI
      pkgs.inputs.llm-agents.claude-desktop
      pkgs.inputs.llm-agents.opencode-desktop
      pkgs.inputs.packages.superset.desktop
      pkgs.inputs.packages.github.copilot-desktop
    ];

  modules.programs = {
    zed.enable = desktop;
    tinkerwell.enable = desktop;
    t3code = {
      enable = true;
      serve.enable = true;
      package = pkgs.inputs.packages.t3code.nightly;
      stateDir = "${config.xdg.dataHome}/t3code";
    };
    k9s.enable = true;
    krr = {
      enableK9sIntegration = true;
      package = pkgs.inputs.packages.kubernetes.krr;
    };
  };
}
