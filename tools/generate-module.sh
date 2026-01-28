#!/usr/bin/env bash
# Generate a new NixOS or Home Manager module with template

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Usage: ./generate-module.sh nixos programs my-program
# Usage: ./generate-module.sh home programs my-program

TYPE=$1       # nixos or home
CATEGORY=$2   # programs, hardware, services, etc.
NAME=$3       # module name

if [[ -z "$TYPE" || -z "$CATEGORY" || -z "$NAME" ]]; then
    echo "Usage: $0 <nixos|home> <category> <name>"
    echo ""
    echo "Examples:"
    echo "  $0 nixos programs docker"
    echo "  $0 home programs neovim"
    echo ""
    echo "Available types: nixos, home"
    echo "Common categories: programs, hardware, services, core, features"
    exit 1
fi

# Determine target directory
if [[ "$TYPE" == "nixos" ]]; then
    TARGET_DIR="$ROOT_DIR/modules/nixos/$CATEGORY/$NAME"
elif [[ "$TYPE" == "home" ]]; then
    TARGET_DIR="$ROOT_DIR/modules/home-manager/$CATEGORY/$NAME"
else
    echo "❌ Invalid type: $TYPE (must be 'nixos' or 'home')"
    exit 1
fi

# Check if module already exists
if [[ -f "$TARGET_DIR/default.nix" ]]; then
    echo "❌ Module already exists at: $TARGET_DIR/default.nix"
    exit 1
fi

# Create directory
mkdir -p "$TARGET_DIR"

# Generate default.nix from template
cat > "$TARGET_DIR/default.nix" <<EOF
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.$CATEGORY.$NAME;
in {
  options.modules.$CATEGORY.$NAME = {
    enable = mkEnableOption "$NAME";
    
    # Add your options here
  };

  config = mkIf cfg.enable {
    # Add your configuration here
  };
}
EOF

echo "✅ Created module at: $TARGET_DIR/default.nix"
echo ""
echo "Next steps:"
echo "  1. Edit the module: \$EDITOR $TARGET_DIR/default.nix"
echo "  2. Add to modules/$TYPE/default.nix:"
echo "     $CATEGORY.$NAME = import ./$CATEGORY/$NAME;"
echo "  3. Enable in host config:"
echo "     modules.$CATEGORY.$NAME.enable = true;"
