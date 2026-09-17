{
  lib,
  cfg,
  pkgs,
  isAttrs,
}:
with lib; let
  package = pkgs.inputs.packages.openwiki;
  # `openwiki integrations install <host>` writes the same MCP entry and skill
  # into ~/.claude.json and ~/.claude/skills — both Nix-owned here, so declare
  # them instead of running the installer.
  integration = "${package}/lib/node_modules/openwiki/integrations/openwiki";
in {
  mcps = {
    openwiki = {
      command = getExe package;
      # `--host` is run metadata only; every client shares this one backend.
      args = ["mcp" "--host" "claude"];
    };
  };

  skills = {
    # Just the SKILL.md; the sibling agents/ yaml are bob/codex host agents.
    openwiki = "${integration}/SKILL.md";
  };

  options = {
    openwiki = {
      enable = mkEnableOption (mdDoc "OpenWiki MCP server and skill for shared ai tooling");
    };
  };

  config = mkIf cfg.openwiki.enable {
    home.packages = [package];
  };

  warnings =
    optional (cfg.openwiki.enable && !(isAttrs cfg.skills))
    "`modules.programs.ai.openwiki.enable` adds the default OpenWiki skill only when `modules.programs.ai.skills` is an attribute set.";
}
