{
  pkgs,
  config,
  lib,
  ...
}: let
  # Google's MCP server for databases. Distributed as a prebuilt static Go
  # binary, so it needs no patchelf — it runs on NixOS as-is.
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

  # Read-only MCP access to the production MariaDB read replica. Brings the
  # SSH tunnel up (MariaDB binds to the Linode private address only), then
  # serves it over stdio. The password comes from an agenix secret
  # decrypted at activation, so MCP clients can spawn this non-interactively
  # (no 1Password unlock prompt) and it never lands in ~/.claude.json.
  prod-db-mcp = pkgs.writeShellScriptBin "prod-db-mcp" ''
    set -euo pipefail

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
    export MYSQL_PASSWORD="$(cat ${config.age.secrets.prod-db-mysql-password.path})"
    exec ${mcp-toolbox}/bin/toolbox --prebuilt mysql --stdio
  '';

  # Same trick as prod-db-mcp: the token can't live in the MCP `env` block
  # (that lands in a world-readable JSON config, and in the repo), so read it
  # from the agenix secret at spawn time instead.
  grafana-mcp = pkgs.writeShellScriptBin "grafana-mcp" ''
    set -euo pipefail
    export GRAFANA_SERVICE_ACCOUNT_TOKEN="$(cat ${config.age.secrets.grafana-service-account-token.path})"
    exec ${lib.getExe pkgs.mcp-grafana} "$@"
  '';
in {
  age.secrets = {
    prod-db-mysql-password.file = ../../../../secrets/prod-db/mysql-password.age;
    grafana-service-account-token.file = ../../../../secrets/grafana/service-account-token.age;
  };

  home.packages = [mcp-toolbox prod-db-mcp grafana-mcp];

  programs = {
    ssh.settings = {
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

      # Tunnel for the read-only MCP database server (see ~/.local/bin/prod-db-mcp).
      # MariaDB binds to the Linode private address only, so 3306 is unreachable
      # from outside the datacenter — the forward target is that private IP.
      "db-prod-read-tunnel" = {
        HostName = "db-prod-read";
        User = "root";
        LocalForward = "33061 192.168.201.159:3306";
        # Fail the ssh call outright if the forward can't bind, instead of
        # succeeding and leaving every query to fail with connection-refused.
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
    zed.enable = true;
    opencode.enable = true;
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
