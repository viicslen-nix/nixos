{
  lib,
  cfg,
  pkgs,
  config,
  inputs,
  isAttrs,
}:
with lib; let
  # The hook scripts are written into $HOME by `mempalace hooks install` at
  # runtime, not shipped by the package, so they are referenced by path.
  hook = script: timeout: [
    {
      hooks = [
        {
          type = "command";
          command = "${config.home.homeDirectory}/.mempalace/hooks/${script}";
          inherit timeout;
        }
      ];
    }
  ];
in {
  # Contributed to `modules.programs.ai.mcps` rather than straight to
  # `programs.mcp.servers`, so it is routed like every other MCP server.
  mcps = {
    mempalace = {
      command = lib.getExe' inputs.packages.packages.${pkgs.stdenv.hostPlatform.system}.python.mempalace "mempalace-mcp";
    };
  };

  hooks = {
    PreCompact = hook "mempal_precompact_hook.sh" 30;
    SessionEnd = hook "mempal_session_end_hook.sh" 10;
    Stop = hook "mempal_save_hook.sh" 30;
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
