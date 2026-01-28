#!/usr/bin/env bash
# Auto-generate module documentation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo "📚 Generating module documentation..."
echo ""

# Generate modules/README.md
echo "  → Generating modules/README.md..."
{
    echo "# Available Modules"
    echo ""
    echo "This document lists all available NixOS and Home Manager modules in this configuration."
    echo ""
    echo "> **Note:** This file is auto-generated. Run \`just update-docs\` to refresh."
    echo ""
    
    for type in nixos home-manager; do
        echo "## ${type^} Modules"
        echo ""
        
        # List all module categories
        for category_path in "$ROOT_DIR/modules/$type/"*/; do
            [[ ! -d "$category_path" ]] && continue
            
            category_name=$(basename "$category_path")
            
            # Skip special files
            [[ "$category_name" =~ \.(nix|md)$ ]] && continue
            
            echo "### \`modules.$category_name\`"
            echo ""
            
            # Count modules in category
            module_count=0
            module_list=""
            
            # List modules in category
            for module_path in "$category_path"*/; do
                [[ ! -d "$module_path" ]] && continue
                module_file="$module_path/default.nix"
                [[ ! -f "$module_file" ]] && continue
                
                module_name=$(basename "$module_path")
                module_list="${module_list}- \`modules.$category_name.$module_name\`\n"
                ((module_count++))
            done
            
            if [[ $module_count -gt 0 ]]; then
                echo -e "$module_list"
            else
                echo "*No modules in this category*"
                echo ""
            fi
        done
    done
    
    echo "---"
    echo ""
    echo "*Last updated: $(date '+%Y-%m-%d %H:%M:%S')*"
    
} > "$ROOT_DIR/modules/README.md"

echo "    ✓ modules/README.md updated"

# Generate hosts/README.md
echo "  → Generating hosts/README.md..."
{
    echo "# Host Configurations"
    echo ""
    echo "This directory contains configuration for all NixOS hosts managed by this flake."
    echo ""
    echo "> **Note:** This file is auto-generated. Run \`just update-docs\` to refresh."
    echo ""
    echo "## Available Hosts"
    echo ""
    
    for host_path in "$ROOT_DIR/hosts/"*/; do
        [[ ! -d "$host_path" ]] && continue
        host=$(basename "$host_path")
        
        # Skip special directories
        [[ "$host" == "_shared" ]] && continue
        
        if [[ -f "$host_path/default.nix" ]]; then
            echo "### \`$host\`"
            echo ""
            
            # Try to extract description from host config
            if grep -q "# Description:" "$host_path/default.nix" 2>/dev/null; then
                description=$(grep "# Description:" "$host_path/default.nix" | sed 's/# Description: //')
                echo "$description"
                echo ""
            fi
            
            # List files in host directory
            echo "**Files:**"
            for file in "$host_path"*.nix; do
                [[ -f "$file" ]] && echo "- \`$(basename "$file")\`"
            done
            echo ""
        fi
    done
    
    echo "## Adding a New Host"
    echo ""
    echo "1. Create a new directory: \`hosts/your-host/\`"
    echo "2. Create \`default.nix\` with your configuration"
    echo "3. Optionally add \`hardware.nix\`, \`disko.nix\`, \`home.nix\`"
    echo "4. Add the host to \`hosts/default.nix\`"
    echo "5. Build with: \`just switch your-host\`"
    echo ""
    echo "---"
    echo ""
    echo "*Last updated: $(date '+%Y-%m-%d %H:%M:%S')*"
    
} > "$ROOT_DIR/hosts/README.md"

echo "    ✓ hosts/README.md updated"

echo ""
echo "✅ Documentation updated successfully!"
