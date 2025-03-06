{
  lib,
  inputs,
  config,
  ...
}:
with lib; {
  imports = builtins.concatLists [
    [
      inputs.nur.modules.nixos.default
      inputs.agenix.nixosModules.default
      inputs.chaotic.nixosModules.default
      config.flake.nixosModules.containers
    ]
    (attrsets.mapAttrsToList (_name: value: value) config.flake.nixosModules.presets)
    (attrsets.mapAttrsToList (_name: value: value) config.flake.nixosModules.desktop)
    (attrsets.mapAttrsToList (_name: value: value) config.flake.nixosModules.hardware)
    (attrsets.mapAttrsToList (_name: value: value) config.flake.nixosModules.programs)
    (attrsets.mapAttrsToList (_name: value: value) config.flake.nixosModules.functionality)
  ];
}
