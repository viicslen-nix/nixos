{
  flake.modules.homeManager.autostart = {
    lib,
    config,
    pkgs,
    ...
  }:
    with lib; let
      name = "autostart";
      namespace = "home";

      cfg = config.${namespace}.${name};

      autostartType = types.either types.package (types.submodule {
        options = {
          package = mkOption {
            type = types.package;
            description = "The package to autostart";
          };
          args = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Arguments to pass to the application";
          };
          delay = mkOption {
            type = types.int;
            default = 0;
            description = "Delay in seconds before starting the application";
          };
        };
      });

      normalizeApp = app:
        if isDerivation app
        then {
          package = app;
          args = [];
          delay = 0;
        }
        else app;

      mkService = app: let
        inherit (normalizeApp app) package args delay;
      in
        nameValuePair "autostart-${package.pname}" {
          Unit = {
            Description = "Autostart ${package.pname}";
            PartOf = ["graphical-session.target"];
            After = ["graphical-session.target"];
          };
          Service = {
            ExecStartPre = mkIf (delay > 0) "${pkgs.coreutils}/bin/sleep ${toString delay}";
            ExecStart = escapeShellArgs ([(getExe package)] ++ args);
            Slice = "app.slice";
          };
          Install.WantedBy = ["graphical-session.target"];
        };
    in {
      options.${namespace}.${name} = mkOption {
        type = types.listOf autostartType;
        default = [];
        description = ''
          Applications started with the graphical session, as systemd user
          services bound to `graphical-session.target`.
          Can be either a package directly or an object with {package, args, delay}.
        '';
        example = lib.literalExpression ''
          [
            pkgs.jetbrains-toolbox
            {
              package = pkgs._1password-gui;
              args = ["--silent"];
              delay = 3;
            }
          ]
        '';
      };

      config = {
        systemd.user.services = listToAttrs (map mkService cfg);
      };
    };
}
