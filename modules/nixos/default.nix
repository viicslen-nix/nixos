# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.

# Import the fully recursive auto-discovery helper from lib
let
  modulesLib = import ../../lib/modules.nix { lib = {}; };
  
  # Recursively auto-import ALL directories and nested modules
  # Automatically discovers categories, supports nesting, handles hybrid directories
  # Excludes: hidden files (.), special dirs (_), all.nix, documentation files
  autoImported = modulesLib.autoImportRecursive ./.;
in
{
  # Manual imports for special cases
  # all.nix is automatically excluded and imported here manually
  all = import ./all.nix;
}
// autoImported  # Merge all auto-discovered modules
