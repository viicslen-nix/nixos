
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
    in
    {
      enable = true;
      mempalace.enable = true;
      mcps = {
        context7.url = "https://mcp.context7.com/mcp";
        gh_grep.url = "https://mcp.grep.app";
        linear.url = "https://mcp.linear.app/mcp";
        google_stitch.url = "https://stitch.googleapis.com/mcp";
      };
      commands = mkMarkdownAttrSet ./commands;
      skills = mkMarkdownAttrSet ./skills;
      context = ./AGENTS.md;
    };
}
