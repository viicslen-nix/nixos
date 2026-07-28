# Enable flake-parts' native dendritic module output, `flake.modules.<class>.<name>`.
# The outer attribute is the module class (nixos, homeManager, generic), so it
# transposes both classes uniformly and applies the correct `_class` — replacing
# the hand-declared `flake.homeManagerModules` option we previously needed.
{inputs, ...}: {
  imports = [inputs.flake-parts.flakeModules.modules];
}
