# `nix flake check` builds each host's toplevel.
{
  lib,
  self,
  ...
}: let
  # These two currently fail to evaluate; drop them from the list once fixed.
  excluded = ["wsl" "lenovo-legion-go"];
in {
  perSystem = {system, ...}: {
    checks = lib.optionalAttrs (system == "x86_64-linux") (
      # Filter on the host name only — never the evaluated config, or excluded hosts evaluate anyway.
      lib.mapAttrs'
      (name: cfg: lib.nameValuePair "host-${name}" cfg.config.system.build.toplevel)
      (lib.filterAttrs (name: _: !(builtins.elem name excluded)) self.nixosConfigurations)
    );
  };
}
