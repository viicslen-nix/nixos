{
  lib,
  pkgs,
  config,
  inputs,
  osConfig,
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
in {
  imports = [inputs.ai.homeManagerModules.ai];

  age.secrets = {
    prod-db-mysql-password.file = ../../secrets/prod-db/mysql-password.age;
    grafana-service-account-token.file = ../../secrets/grafana/service-account-token.age;
    typesafe-api-key.file = ../../secrets/typesafe/api-key.age;
    cliproxyapi-api-key.file = ../../secrets/cliproxyapi/api-key.age;
  };

  home.packages = with pkgs;
    [
      # Cloud access
      awscli
      linode-cli

      # MCP servers
      mcp-toolbox
      prod-db-mcp
      grafana-mcp
    ]
    ++ import ./scripts.nix {inherit pkgs;};

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
  };

  # The gateway firewall flags backticks/`$(...)` as shell injection in every
  # argument except these keys; the list replaces its built-in defaults (the
  # first 15), so keep them. Only the shell scan is skipped — SQL and
  # path-traversal scans still run on these keys.
  xdg.configFile."mcp-gateway/firewall.env".text = ''
    MCP_GATEWAY_FIREWALL_SKIP_KEYS=description,body,summary,content,message,prompt,comment,comment_body,title,rationale,context,notes,rollback,ac,acceptance_criteria,sql,text,old_string,new_string
  '';

  modules.programs = {
    ai = {
      integrations.gateway.settings.env_files = ["~/.config/mcp-gateway/firewall.env"];
      integrations.jev = {
        enable = osConfig.modules.presets.desktop.enable;
        typesafeApiKeyFile = config.age.secrets.typesafe-api-key.path;
        textModel = {
          baseUrl = "https://cliproxyapi.tailb6b9b6.ts.net/v1";
          # Haiku fences its JSON in ```, which jev rejects.
          model = "claude-sonnet-5-5";
          apiKeyFile = config.age.secrets.cliproxyapi-api-key.path;
        };
      };
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
