
{ inputs, ... }:
{
  modules.programs.ai =
    let
      mkMarkdownAttrSet = dir:
        let
          entries = builtins.readDir dir;
          markdownFiles = builtins.filter (
            name: entries.${name} == "regular" && builtins.match ".*\\.md" name != null
          ) (builtins.attrNames entries);
        in
        builtins.listToAttrs (map (name: {
          name = builtins.elemAt (builtins.match "(.*)\\.md" name) 0;
          value = dir + "/${name}";
        }) markdownFiles);

      mkSkillAttrSet = dir:
        let
          entries = builtins.readDir dir;
          skillEntries = builtins.filter (
            name:
            let
              kind = entries.${name};
            in
            kind == "directory" || (kind == "regular" && builtins.match ".*\\.md" name != null)
          ) (builtins.attrNames entries);
        in
        builtins.listToAttrs (map (name: {
          name = if entries.${name} == "directory" then name else builtins.elemAt (builtins.match "(.*)\\.md" name) 0;
          value = dir + "/${name}";
        }) skillEntries);

      # A flake input's outPath is a *string*, but home-manager's claude-code
      # module branches on `lib.isPath` to decide "copy this directory" vs
      # "write this string as the file body" — so it has to be coerced back to
      # a real path. `/. + str` refuses strings carrying store context, and the
      # context is pointless here: a flake input is a source that is already
      # realised at eval time, never a derivation that needs building.
      fromInput = input: sub: /. + (builtins.unsafeDiscardStringContext "${input}/${sub}");

      # Skills taken verbatim from github:mattpocock/skills. Curated by name —
      # that repo carries more than we want (in-progress/, misc/, deprecated/).
      upstream = category: name: fromInput inputs.mattpocock-skills "skills/${category}/${name}";

      upstreamSkills = builtins.listToAttrs (
        map (spec: {
          name = builtins.elemAt spec 1;
          value = upstream (builtins.elemAt spec 0) (builtins.elemAt spec 1);
        }) [
          [ "engineering" "codebase-design" ]
          [ "engineering" "diagnosing-bugs" ]
          [ "engineering" "domain-modeling" ]
          [ "engineering" "grill-with-docs" ]
          [ "engineering" "implement" ]
          [ "engineering" "improve-codebase-architecture" ]
          [ "engineering" "prototype" ]
          [ "engineering" "research" ]
          [ "engineering" "resolving-merge-conflicts" ]
          [ "engineering" "tdd" ]
          [ "engineering" "to-spec" ]
          [ "engineering" "to-tickets" ]
          [ "engineering" "triage" ]
          [ "engineering" "wayfinder" ]
          [ "productivity" "grill-me" ]
          [ "productivity" "grilling" ]
          [ "productivity" "handoff" ]
          [ "productivity" "wait-what" ]
        ]
      );
    in
    {
      enable = true;
      mempalace.enable = true;
      coderabbit.enable = true;
      context = ./AGENTS.md;
      # Local last: a directory under ./skills shadows any upstream copy.
      # effective-html is taken whole — `html` routes to the html-* specialists,
      # and they only resolve if all of them are present.
      skills =
        upstreamSkills
        // mkSkillAttrSet (fromInput inputs.effective-html "skills")
        // mkSkillAttrSet ./skills;
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
