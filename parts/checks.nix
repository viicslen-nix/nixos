# `nix flake check` builds each host's toplevel, so CI can gate on a full
# evaluation + build of every configuration. Replaces the hand-rolled
# `just build-all` bash loop.
#
# wsl and lenovo-legion-go are intentionally excluded: they currently fail to
# evaluate for reasons that predate this work (wsl's nixpkgs.hostPlatform type
# conflict; lenovo's missing `inputs.chaotic`). Add them here once fixed.
#
# The filter keys off the host NAME only — never the evaluated config — so
# listing checks does not force a (possibly failing) host to evaluate. Every
# host is x86_64-linux, so the checks are only emitted there.
{
  lib,
  self,
  ...
}: let
  excluded = ["wsl" "lenovo-legion-go"];
in {
  perSystem = {system, ...}: {
    checks = lib.optionalAttrs (system == "x86_64-linux") (
      lib.mapAttrs'
      (name: cfg: lib.nameValuePair "host-${name}" cfg.config.system.build.toplevel)
      (lib.filterAttrs (name: _: !(builtins.elem name excluded)) self.nixosConfigurations)
    );
  };
}
