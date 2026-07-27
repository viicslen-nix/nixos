{pkgs, ...}: {
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
    ai.commands.skill-assessment-review = ./ai/skill-assessment-review.md;
  };
}
