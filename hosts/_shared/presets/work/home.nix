{pkgs, ...}: {
  programs = {
    ssh.matchBlocks = {
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

    claude-code = let
      claudeCodeRepo = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-code";
        rev = "main";
        sha256 = "sha256-2Kd4oSU3vuDlbo1024hyY0cBA5oeeBPaMWmS3caH6wc=";
      };
    in {
      enable = true;
      package = pkgs.inputs.llm-agents.claude-code;
      plugins = [
        "${claudeCodeRepo}/plugins/ralph-wiggum"
      ];
    };
    gemini-cli = {
      enable = true;
      package = pkgs.inputs.llm-agents.gemini-cli;
    };
    github-copilot-cli = {
      enable = true;
      package = pkgs.inputs.llm-agents.copilot-cli;
    };
  };

  modules.programs = {
    k9s.enable = true;
    zed.enable = true;
    opencode.enable = true;
    krr = {
      enable = true;
      enableK9sIntegration = true;
      package = pkgs.inputs.packages.kubernetes.krr;
    };
  };
}
