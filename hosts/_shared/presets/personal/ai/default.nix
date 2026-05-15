
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
      coderabbit.enable = true;
      context = ./AGENTS.md;
      skills = mkMarkdownAttrSet ./skills;
      commands = mkMarkdownAttrSet ./commands;
      mcps = {
        context7.url = "https://mcp.context7.com/mcp";
        gh_grep.url = "https://mcp.grep.app";
        linear.url = "https://mcp.linear.app/mcp";
        google_stitch.url = "https://stitch.googleapis.com/mcp";
      };
    };
}
