{inputs, outputs, ...}: {
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.opencode.homeManagerModules.default
    outputs.homeManagerModules.defaults
  ];
}
