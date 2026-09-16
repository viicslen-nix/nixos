{ inputs, ... }:
let
  inherit (inputs.self.lib.skills)
    mkMarkdownAttrSet
    mkSkillAttrSet
    selectFromInput
    patchSkill
    ;

  mattpocock = inputs.mattpocock-skills;

  # Curated by name — the upstream repo also carries in-progress/misc/deprecated.
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
    "skills/productivity/writing-for-agents"
  ];

  patchedSkills = {
    grilling = patchSkill
      "${mattpocock}/skills/productivity/grilling/SKILL.md"
      (import ./skill-patches/grilling.nix);
    implement = patchSkill
      "${mattpocock}/skills/engineering/implement/SKILL.md"
      (import ./skill-patches/implement.nix);
  };
in
{
  age.secrets.stitch-api-key.file = ../../../../../secrets/stitch/api-key.age;
  # Not the gateway's `env_files` — it can't expand the path, sending an empty header.
  systemd.user.services.mcp-gateway.Service.EnvironmentFile = "%t/agenix/stitch-api-key";

  modules.programs.claude-code = {
    marketplaces = {
      mempalace = "MemPalace/mempalace";
      ponytail = "DietrichGebert/ponytail";
      worktrunk = "max-sixty/worktrunk";
      workmux = "raine/workmux";
    };

    plugins = {
      "document-skills@anthropic-agent-skills" = true;
      "example-skills@anthropic-agent-skills" = false;
      "laravel-simplifier@laravel" = true;
      "mempalace@mempalace" = true;
      "phpstorm-plugin@phpstorm-marketplace" = true;
      "ponytail@ponytail" = true;
      "worktrunk@worktrunk" = true;
      # `workmux setup --hooks` can't install these — settings.json is a store symlink.
      "workmux-status@workmux" = true;
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
    # Order matters — last wins, and ./skills shadows both upstream layers.
    skills = upstreamSkills // patchedSkills // mkSkillAttrSet ./skills;
    commands = mkMarkdownAttrSet ./commands;
    mcps = {
      # Not `oauth.enabled` — accounts.google.com has no registration_endpoint.
      google_stitch = {
        url = "https://stitch.googleapis.com/mcp";
        headers."X-Goog-Api-Key" = "\${STITCH_API_KEY}";
      };
      context7 = {
        url = "https://mcp.context7.com/mcp";
        oauth.enabled = true;
      };
      gh_grep = {
        url = "https://mcp.grep.app";
        protocol_version = "2025-06-18";
      };
      linear = {
        url = "https://mcp.linear.app/mcp";
        oauth.enabled = true;
      };
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
