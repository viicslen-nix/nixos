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

    gemini-cli = {
      enable = true;
      package = pkgs.unstable.gemini-cli;
    };
    github-copilot-cli = {
      enable = true;
      package = pkgs.unstable.github-copilot-cli;
    };
    claude-code = {
      enable = true;
      package = pkgs.unstable.claude-code;
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
