#!/usr/bin/env bash
# Migration script to update old module paths to new structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo "🔄 Migrating module paths from functionality.* to core/services/features.*"
echo ""

# Define the migration mappings
declare -A CORE_MODULES=(
  ["functionality.sound"]="core.sound"
  ["functionality.network"]="core.network"
  ["functionality.theming"]="core.theming"
  ["functionality.localization"]="core.localization"
)

declare -A SERVICE_MODULES=(
  ["functionality.oom"]="services.oom"
  ["functionality.backups"]="services.backups"
  ["functionality.impermanence"]="services.impermanence"
  ["functionality.power-management"]="services.power-management"
)

declare -A FEATURE_MODULES=(
  ["functionality.app-images"]="features.app-images"
  ["functionality.virtual-machines"]="features.virtual-machines"
  ["functionality.miami-bus-tracker"]="features.miami-bus-tracker"
)

# Function to update file
update_file() {
  local file=$1
  local temp_file="${file}.tmp"
  
  cp "$file" "$temp_file"
  
  # Update core modules
  for old in "${!CORE_MODULES[@]}"; do
    new="${CORE_MODULES[$old]}"
    sed -i "s/${old}/${new}/g" "$temp_file"
  done
  
  # Update service modules
  for old in "${!SERVICE_MODULES[@]}"; do
    new="${SERVICE_MODULES[$old]}"
    sed -i "s/${old}/${new}/g" "$temp_file"
  done
  
  # Update feature modules
  for old in "${!FEATURE_MODULES[@]}"; do
    new="${FEATURE_MODULES[$old]}"
    sed -i "s/${old}/${new}/g" "$temp_file"
  done
  
  # Check if file changed
  if ! diff -q "$file" "$temp_file" > /dev/null 2>&1; then
    mv "$temp_file" "$file"
    echo "  ✓ Updated: $file"
    return 0
  else
    rm "$temp_file"
    return 1
  fi
}

# Find and update all nix files in hosts and presets
updated_count=0

for file in $(find hosts/ modules/nixos/presets/ -name "*.nix" -type f 2>/dev/null); do
  if grep -q "functionality\." "$file" 2>/dev/null; then
    if update_file "$file"; then
      ((updated_count++))
    fi
  fi
done

echo ""
echo "✅ Migration complete! Updated $updated_count files."
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Test build: just validate"
echo "  3. Commit: git add . && git commit -m 'Reorganize modules: functionality → core/services/features'"
