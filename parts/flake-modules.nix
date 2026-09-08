# Enable flake-parts' native dendritic module output, `flake.modules.<class>.<name>`.
{inputs, ...}: {
  imports = [inputs.flake-parts.flakeModules.modules];
}
