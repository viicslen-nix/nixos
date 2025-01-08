{
  lib,
  config,
  ...
}:
with lib; let
  name = "tmate";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config.programs.tmate = mkIf cfg.enable {
    enable = true;

    extraConfig = ''
      ${builtins.unsafeDiscardStringContext (builtins.readFile ./tmux.conf)}
    '';
  };
}
