{
  inputs,
  system,
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
  };
in
  pkgs.mkShell {
    packages = with pkgs; [
      zsh
      (php.buildEnv {
        extensions = {
          enabled,
          all,
        }:
          enabled
          ++ (with all; [
            xdebug
            imagick
            redis
          ]);
        extraConfig = ''
          xdebug.mode=debug
        '';
      })
      (
        php.withExtensions ({
          all,
          enabled,
        }:
          enabled
          ++ (with all; [
            imagick
            redis
          ]))
      )
      .packages
      .composer
      nodejs_20
      corepack_20
      bun
      stripe-cli
      python3
      python311Packages.cmake
      cypress
    ];

    shellHook = ''
      export CYPRESS_INSTALL_BINARY=0
      export CYPRESS_RUN_BINARY=${pkgs.cypress}/bin/Cypress
      exec zsh
    '';
  }
