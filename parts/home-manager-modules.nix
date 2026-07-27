# flake-parts declares `flake.nixosModules` as a mergeable option, but has no
# equivalent for home-manager. Without a declaration it falls through to the
# freeform type, which does not merge — so the many per-module registrations
# collide instead of combining. Declare it here, mirroring flake-parts' own
# nixosModules option.
{
  lib,
  flake-parts-lib,
  moduleLocation,
  ...
}: {
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    homeManagerModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
      apply =
        lib.mapAttrs (k: v: {
          _class = "homeManager";
          _file = "${toString moduleLocation}#homeManagerModules.${k}";
          imports = [v];
        });
      description = ''
        home-manager modules, registered by the files under
        ../modules/home-manager.
      '';
    };
  };
}
