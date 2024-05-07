{inputs, ...}: {
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

    config = {
      modules = [
        {
          name = "applications";
          prefix = "";
        }
        {
          name = "ssh";
          prefix = "";
          switcher_exclusive = true;
        }
        {
          name = "finder";
          prefix = "";
          switcher_exclusive = true;
        }
      ];
    };

    style = ''
      * {
        color: #dcd7ba;
      }
    '';
  };
}
