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
    inputs.ai.homeManagerModules.default
    inputs.hunk.homeManagerModules.default
    homeModules.programs.ray
    homeModules.programs.tinkerwell
    homeModules.programs.k9s
    homeModules.programs.krr
  ];

  age.secrets.intelephense = {
    file = ../../secrets/intelephense/licence.age;
    path = "${config.home.homeDirectory}/intelephense/licence.txt";
  };

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
      atlas
      percona-toolkit

      # AI
      # llm-agents installs the CLI only as `agy`; resolve it from PATH, or the proxy's `agy` launcher is bypassed.
      (writeShellScriptBin "antigravity" ''exec agy "$@"'')
    ]
    ++ import ./scripts.nix {inherit pkgs;}
    ++ lib.optionals desktop [
      # Editors
      jetbrains-toolbox
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

  programs = {
    claude-code = let
      claudeCodeRepo = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-code";
        rev = "53f9910f6ef015ddda6a4b5fceab5dd745af7f4c";
        sha256 = "sha256-ba7eTo6L4Xdb86kS9khFKXOIWWBmlNfUk8W39cSLWeM=";
      };
    in {
      enable = true;
      package = pkgs.inputs.llm-agents.claude-code;
      plugins.ralph-wiggum = "${claudeCodeRepo}/plugins/ralph-wiggum";
    };
    antigravity-cli = {
      enable = true;
      package = pkgs.inputs.llm-agents.antigravity-cli;
    };
    github-copilot-cli = {
      enable = true;
      package = pkgs.inputs.llm-agents.copilot-cli;
    };
    codex = {
      enable = true;
      package = pkgs.inputs.llm-agents.codex;
    };
    pi.coding-agent.enable = true;
    hunk = {
      enable = true;
      enableGitIntegration = true;
      settings = {
        mode = "auto";
        wrap_lines = false;
        line_numbers = true;
        transparent_background = false;

        # Binding a key steals it from its default holder — rehome, don't drop.
        keybindings = {
          "hunk.review.scrollCodeLeft" = ["h" "left" "shift+left"];
          "hunk.review.scrollCodeRight" = ["l" "right" "shift+right"];
          "hunk.view.toggleLineNumbers" = "ctrl+l";
          "hunk.review.pageDown" = ["ctrl+f" "pagedown" "space"];
          "hunk.review.pageUp" = ["ctrl+b" "pageup" "shift+space"];
          "hunk.review.halfPageDown" = ["ctrl+d" "d"];
          "hunk.review.halfPageUp" = ["ctrl+u" "u"];
        };
      };
    };
  };

  modules.programs = {
    claude-code.mods.readable-output.enable = true;
    zed.enable = desktop;
    ray.enable = desktop;
    tinkerwell.enable = desktop;
    t3code = {
      enable = true;
      desktopApp = true;
      serve.enable = true;
      package = pkgs.inputs.packages.t3code.nightly;
    };
    opencode = {
      enable = true;
      default = "v1";
    };
    opencode1.enable = true;
    k9s.enable = true;
    krr = {
      enableK9sIntegration = true;
      package = pkgs.inputs.packages.kubernetes.krr;
    };
  };
}
