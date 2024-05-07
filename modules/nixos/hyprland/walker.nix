{
  imports = [
    inputs.walker.homeManagerModules.walker
  ];

  nix.settings = {
    substituters = ["https://walker.cachix.org"];
    trusted-public-keys = ["walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="];
  };

  programs.walker = {
    enable = true;
    runAsService = true;

    # All options from the config.json can be used here.
    config = {
      placeholder = "Example";
      fullscreen = true;
      list = {
        height = 200;
      };
      modules = [
        {
          name = "websearch";
          prefix = "?";
        }
        {
          name = "switcher";
          prefix = "/";
        }
      ];
    };

    # If this is not set the default styling is used.
    style = ''
      * {
        color: #dcd7ba;
      }
    '';
  };
}