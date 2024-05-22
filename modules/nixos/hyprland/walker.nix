{inputs, ...}: {
  imports = [
    inputs.walker.homeManagerModules.walker
  ];

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
