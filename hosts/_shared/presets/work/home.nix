{
  pkgs,
  config,
  lib,
  osConfig,
  homeModules,
  ...
}: let
  # Prebuilt static Go binary — no patchelf needed.
  mcp-toolbox =
    pkgs.runCommand "mcp-toolbox-1.8.0" {
      src = pkgs.fetchurl {
        url = "https://storage.googleapis.com/mcp-toolbox-for-databases/v1.8.0/linux/amd64/toolbox";
        hash = "sha256-jArDuXhdFCStPWZ5nCbF2mldc8dMRSJaMBaJv3051xQ=";
      };
    } ''
      mkdir -p $out/bin
      cp $src $out/bin/toolbox
      chmod +x $out/bin/toolbox
    '';

  # Re-derive it — mcp-gateway spawns backends with XDG_RUNTIME_DIR unset.
  xdgRuntimeDir = ''export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"'';

  prod-db-mcp = pkgs.writeShellScriptBin "prod-db-mcp" ''
    set -euo pipefail

    ${xdgRuntimeDir}

    PORT="''${MYSQL_PORT:-33061}"

    # ponytail: ControlPersist means only the first call actually dials; the
    # rest reuse the master. `|| true` because ssh exits non-zero when the
    # forward is already bound, which is the success case here.
    ssh -fN db-prod-read-tunnel 2>/dev/null || true

    # Fail once, loudly, instead of letting every query surface as a
    # confusing connection-refused.
    if ! timeout 5 bash -c "</dev/tcp/127.0.0.1/$PORT" 2>/dev/null; then
      echo "prod-db-mcp: tunnel not listening on 127.0.0.1:$PORT" >&2
      exit 1
    fi

    # The mysql prebuilt refuses to start unless all of these are set.
    # Only the password is a secret; the rest just describe the tunnel target.
    export MYSQL_HOST="''${MYSQL_HOST:-127.0.0.1}"
    export MYSQL_PORT="$PORT"
    export MYSQL_USER="''${MYSQL_USER:-mcp_readonly}"
    export MYSQL_DATABASE="''${MYSQL_DATABASE:-mylisterhub_central}"
    # Assign, then export: `export VAR="$(…)"` returns export's status, so a
    # failed read would sail past `set -e` and reach toolbox as an empty
    # password — surfacing as a confusing "Access denied" instead of the real
    # "secret missing".
    MYSQL_PASSWORD="$(cat ${config.age.secrets.prod-db-mysql-password.path})"
    export MYSQL_PASSWORD
    exec ${mcp-toolbox}/bin/toolbox --prebuilt mysql --stdio
  '';

  # Never put the token in the MCP `env` block — that lands in a readable JSON.
  grafana-mcp = pkgs.writeShellScriptBin "grafana-mcp" ''
    set -euo pipefail
    ${xdgRuntimeDir}
    GRAFANA_SERVICE_ACCOUNT_TOKEN="$(cat ${config.age.secrets.grafana-service-account-token.path})"
    export GRAFANA_SERVICE_ACCOUNT_TOKEN
    exec ${lib.getExe pkgs.mcp-grafana} "$@"
  '';

  # v1 and v2 both live in <XDG>/opencode, so v2 gets its own XDG roots — it
  # appends "opencode" itself, hence the nested opencode2/opencode dirs.
  # XDG_CONFIG_HOME stays untouched on purpose: moving it would send every
  # child process opencode spawns (gh, git, nu) to an empty config dir.
  opencode2 = pkgs.writeShellScriptBin "opencode2" ''
    export OPENCODE_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/opencode2"
    export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/opencode2"
    export XDG_STATE_HOME="''${XDG_STATE_HOME:-$HOME/.local/state}/opencode2"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}/opencode2"
    exec ${lib.getExe' pkgs.inputs.llm-agents.opencode2 "opencode2"} "$@"
  '';
in {
  imports = [
    homeModules.programs.ai
    homeModules.programs.claude-code
  ];

  age.secrets = {
    prod-db-mysql-password.file = ../../../../secrets/prod-db/mysql-password.age;
    grafana-service-account-token.file = ../../../../secrets/grafana/service-account-token.age;
    intelephense = {
      file = ../../../../secrets/intelephense/licence.age;
      path = "${config.home.homeDirectory}/intelephense/licence.txt";
    };
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
  };

  home.packages = [
    mcp-toolbox
    prod-db-mcp
    grafana-mcp
    # llm-agents installs the CLI only as `agy`.
    (pkgs.runCommand "antigravity-alias" {} ''
      mkdir -p $out/bin
      ln -s ${lib.getExe config.programs.antigravity-cli.package} $out/bin/antigravity
    '')
    pkgs.inputs.llm-agents.opencode-desktop
    opencode2
  ];

  programs = {
    ssh.settings = {
      "work.neoscode.com".ProxyCommand = "${lib.getExe pkgs.cloudflared} access ssh --hostname %h";

      "FmTod" = {
        HostName = "webapps";
        User = "fmtod";
      };

      "SellDiam" = {
        HostName = "webapps";
        User = "inventory";
      };

      "DOS" = {
        HostName = "storesites";
        User = "dostov";
      };

      "BLVD" = {
        HostName = "storesites";
        User = "diamondblvd";
      };

      "EXB" = {
        HostName = "storesites";
        User = "extrabrilliant";
      };

      "DTC" = {
        HostName = "storesites";
        User = "diamondtraces";
      };

      "NFC" = {
        HostName = "storesites";
        User = "naturalfacet";
      };

      "TJD" = {
        HostName = "storesites";
        User = "tiffanyjonesdesigns";
      };

      "47DD" = {
        HostName = "storesites";
        User = "47diamonddistrict";
      };

      "PELA" = {
        HostName = "storesites";
        User = "pelagrino";
      };

      # The forward target must stay the private IP — 3306 is datacenter-only.
      "db-prod-read-tunnel" = {
        HostName = "db-prod-read";
        User = "root";
        LocalForward = "33061 192.168.201.159:3306";
        # Keep: without it a failed forward still exits 0 and every query breaks.
        ExitOnForwardFailure = "yes";
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
        ControlMaster = "auto";
        ControlPersist = "30m";
      };
    };

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
  };

  modules.programs = {
    zed.enable = osConfig.modules.presets.desktop.enable;
    opencode.enable = true;
    k9s.enable = true;
    krr = {
      enableK9sIntegration = true;
      package = pkgs.inputs.packages.kubernetes.krr;
    };
    ai = {
      commands = {
        skill-assessment-review = ./ai/skill-assessment-review.md;
        work-summary = ./ai/work-summary.md;
      };
      skills = {
        ci-pipeline = ./ai/ci-pipeline.md;
        cd-pipeline = ./ai/cd-pipeline.md;
        prod-db-operations = ./ai/prod-db-operations.md;
      };
      mcps = with lib;
      with pkgs; {
        prod-db.command = getExe prod-db-mcp;
        grafana = {
          command = getExe grafana-mcp;
          env.GRAFANA_URL = "https://grafana.mylisterhub.com";
        };
      };
    };
  };
}
