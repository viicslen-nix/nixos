{
  flake.modules.homeManager.herdr = {
    lib,
    config,
    ...
  }: let
    cfg = config.modules.programs.herdr;
  in {
    options.modules.programs.herdr.enable = lib.mkEnableOption "Herdr" // {default = true;};

    config.programs.herdr = lib.mkIf cfg.enable {
      enable = true;
      settings = {
        onboarding = false;
        keys = {
          prefix = "ctrl+space";
          split_vertical = "prefix+|";
        };
      };
    };
  };
}
