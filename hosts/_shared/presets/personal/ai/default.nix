{ inputs, ... }:
let
  inherit (inputs.self.lib.skills)
    mkMarkdownAttrSet
    mkSkillAttrSet
    selectFromInput
    patchSkill
    ;

  mattpocock = inputs.mattpocock-skills;

  # Skills taken verbatim from github:mattpocock/skills. Curated by name — that
  # repo carries more than we want (in-progress/, misc/, deprecated/).
  upstreamSkills = selectFromInput mattpocock [
    "skills/engineering/codebase-design"
    "skills/engineering/diagnosing-bugs"
    "skills/engineering/domain-modeling"
    "skills/engineering/grill-with-docs"
    "skills/engineering/implement"
    "skills/engineering/improve-codebase-architecture"
    "skills/engineering/prototype"
    "skills/engineering/research"
    "skills/engineering/resolving-merge-conflicts"
    "skills/engineering/tdd"
    "skills/engineering/to-spec"
    "skills/engineering/to-tickets"
    "skills/engineering/triage"
    "skills/engineering/wayfinder"
    "skills/productivity/grill-me"
    "skills/productivity/grilling"
    "skills/productivity/handoff"
    "skills/productivity/wait-what"
  ];

  # The same upstream skills, with the local edits in ./skill-patches rewritten
  # in — so `just update-input mattpocock-skills` keeps flowing, and a reword
  # that moves an anchor fails the build instead of silently reverting.
  patchedSkills = {
    grilling = patchSkill
      "${mattpocock}/skills/productivity/grilling/SKILL.md"
      (import ./skill-patches/grilling.nix);
  };
in
{
  modules.programs.claude-code = {
    marketplaces = {
      mempalace = "MemPalace/mempalace";
      ponytail = "DietrichGebert/ponytail";
      worktrunk = "max-sixty/worktrunk";
    };

    plugins = {
      "document-skills@anthropic-agent-skills" = true;
      "example-skills@anthropic-agent-skills" = false;
      "laravel-simplifier@laravel" = true;
      "mempalace@mempalace" = true;
      "phpstorm-plugin@phpstorm-marketplace" = true;
      "ponytail@ponytail" = true;
      "worktrunk@worktrunk" = true;
      "playground@claude-plugins-official" = true;
    };
  };

  modules.programs.ai = {
    enable = true;
    gateway.enable = true;
    superset.enable = true;
    mempalace.enable = true;
    coderabbit.enable = true;
    context = ./AGENTS.md;
    # Three layers, last wins: upstream verbatim, then the patched copies, then
    # a directory under ./skills, which shadows either outright. That directory
    # also holds the vendored collections (`just vendor-skills`), which are
    # plain checked-in skills as far as this is concerned.
    skills = upstreamSkills // patchedSkills // mkSkillAttrSet ./skills;
    commands = mkMarkdownAttrSet ./commands;
    mcps = {
      context7.url = "https://mcp.context7.com/mcp";
      gh_grep.url = "https://mcp.grep.app";
      linear.url = "https://mcp.linear.app/mcp";
      google_stitch.url = "https://stitch.googleapis.com/mcp";
      playwright = {
        command = "npx";
        args = [
          "-y"
          "@playwright/mcp@latest"
          "--ignore-https-errors"
          "--browser"
          "chromium"
        ];
      };
    };
  };
}
