#!/usr/bin/env bash
# Validate NixOS configuration before committing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo "🔍 Validating NixOS configuration..."
echo ""

# Check flake syntax
echo "  → Checking flake syntax..."
if nix flake check --no-build 2>&1 | grep -q "error:"; then
    echo "❌ Flake check failed!"
    exit 1
fi
echo "    ✓ Flake syntax OK"

# Check formatting (only if alejandra is available)
if command -v alejandra &> /dev/null; then
    echo "  → Checking nix formatting..."
    if ! alejandra --check . &> /dev/null; then
        echo "    ⚠️  Formatting issues found. Run 'nix fmt' to fix."
    else
        echo "    ✓ Formatting OK"
    fi
fi

# Validate all hosts can build (dry-run)
echo "  → Validating host configurations..."
for host_dir in hosts/*/; do
    host=$(basename "$host_dir")
    # Skip non-directories and special files
    [[ ! -d "$host_dir" ]] && continue
    [[ "$host" == "_shared" ]] && continue
    
    if [[ -f "$host_dir/default.nix" ]]; then
        echo "    • Checking $host..."
        if ! nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --dry-run --quiet 2>&1; then
            echo "      ❌ Failed to validate $host"
            exit 1
        fi
        echo "      ✓ $host OK"
    fi
done

echo ""
echo "✅ Configuration validation passed!"
