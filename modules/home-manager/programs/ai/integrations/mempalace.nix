{
  lib,
  cfg,
  pkgs,
  inputs,
  isAttrs,
}:
with lib; {
  # Contributed to `modules.programs.ai.mcps` rather than straight to
  # `programs.mcp.servers`, so it is routed like every other MCP server.
  mcps = {
    mempalace = {
      command = lib.getExe' inputs.packages.packages.${pkgs.stdenv.hostPlatform.system}.python.mempalace "mempalace-mcp";
    };
  };

  commands = {
    mempalace-help = ../commands/mempalace/help.md;
    mempalace-init = ../commands/mempalace/init.md;
    mempalace-mine = ../commands/mempalace/mine.md;
    mempalace-search = ../commands/mempalace/search.md;
    mempalace-status = ../commands/mempalace/status.md;
  };

  skills = {
    mempalace = ../skills/mempalace.md;
  };

  options = {
    mempalace = {
      enable = mkEnableOption (mdDoc "mempalace integration for shared ai tooling");
    };
  };

  warnings =
    optional (cfg.mempalace.enable && !(isAttrs cfg.skills))
    "`modules.programs.ai.mempalace.enable` adds a default mempalace skill only when `modules.programs.ai.skills` is an attribute set.";
}
