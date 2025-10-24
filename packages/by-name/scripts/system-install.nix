{
  writeShellScriptBin,
  stdenv,
  lib,
  gum,
  git,
  nixos-generate-config,
  nixos-install,
  nano,
  ...
}:
with lib;
  writeShellScriptBin "system-install" ''
        #!${stdenv.shell}

        # Check if running with sudo permissions
        if [ "$EUID" -ne 0 ]; then
          echo "Error: This script must be run with sudo privileges."
          echo "Please run: sudo system-install"
          exit 1
        fi

        TARGET_DIR="/mnt/etc/nixos"

        while getopts "d:" opt; do
          case ''${opt} in
            d )
              TARGET_DIR=''${OPTARG}
              ;;
            \? )
              echo "Usage: system-install [-d target_directory]"
              echo "  -d: Target directory for NixOS configuration (default: /mnt/etc/nixos)"
              exit 1
              ;;
          esac
        done

        echo "=== NixOS Installation Setup ==="
        echo "Target directory: $TARGET_DIR"

        # Check if /mnt is mounted
        if ! mountpoint -q /mnt; then
          echo "Error: /mnt is not a mount point. Please mount your target filesystem to /mnt first."
          exit 1
        fi

        # Check if /mnt/boot exists
        if [ ! -d "/mnt/boot" ]; then
          echo "Error: /mnt/boot directory does not exist. Please ensure your boot partition is mounted."
          exit 1
        fi

        echo "✓ Mount points validated"

        # Create parent directories if they don't exist
        PARENT_DIR=$(dirname "$TARGET_DIR")
        if [ ! -d "$PARENT_DIR" ]; then
          echo "Creating parent directories: $PARENT_DIR"
          mkdir -p "$PARENT_DIR"
          if [ $? -ne 0 ]; then
            echo "Error: Failed to create parent directories."
            exit 1
          fi
        fi

        # Clone the NixOS configuration repository
        echo "Cloning NixOS configuration repository..."
        if [ -d "$TARGET_DIR" ]; then
          echo "Error: $TARGET_DIR already exists. Removing it first..."
          exit 1
        fi

        ${getExe git} clone --recurse-submodules https://github.com/viicslen/nixos "$TARGET_DIR"
        if [ $? -ne 0 ]; then
          echo "Error: Failed to clone repository."
          exit 1
        fi

        echo "✓ Repository cloned successfully"

        # Change to the nixos directory
        cd "$TARGET_DIR"

        # Check for existing hosts or create new one
        HOSTS_DIR="./hosts"
        if [ ! -d "$HOSTS_DIR" ]; then
          echo "Error: Hosts directory '$HOSTS_DIR' not found in repository."
          exit 1
        fi

        # Get existing hostnames
        EXISTING_HOSTS=$(find ''${HOSTS_DIR}/ -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -n 1 basename | sort)

        # Create selection options
        OPTIONS="$EXISTING_HOSTS"$'\n'"[Create New Host]"

        echo "Select a host configuration:"
        SELECTION=$(echo "$OPTIONS" | ${getExe gum} choose)

        if [ -z "$SELECTION" ]; then
          echo "Error: No selection made."
          exit 1
        fi

        if [ "$SELECTION" = "[Create New Host]" ]; then
          # Create new host
          echo "Enter new hostname:"
          HOSTNAME=$(${getExe gum} input --placeholder "my-nixos-host")

          if [ -z "$HOSTNAME" ]; then
            echo "Error: No hostname provided."
            exit 1
          fi

          HOST_DIR="''${HOSTS_DIR}/''${HOSTNAME}"

          if [ -d "$HOST_DIR" ]; then
            echo "Error: Host directory '$HOST_DIR' already exists."
            exit 1
          fi

          echo "Creating host directory: $HOST_DIR"
          mkdir -p "$HOST_DIR"

          # Generate hardware configuration
          echo "Generating hardware configuration..."
          ${getExe nixos-generate-config} --show-hardware-config > "''${HOST_DIR}/hardware.nix"

          if [ $? -ne 0 ]; then
            echo "Error: Failed to generate hardware configuration."
            rm -rf "$HOST_DIR"
            exit 1
          fi

          # Create host's default.nix
          cat > "''${HOST_DIR}/default.nix" << EOF
    {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = [
        ./hardware.nix
      ];

      # Add your host-specific configuration here
      modules = {
        functionality = {
          theming.enable = true;
          network.hostName = "$HOSTNAME";
        };

        presets = {
          base.enable = true;
          personal.enable = true;
        };

        programs.ld.enable = true;
      };
    }
    EOF

          echo "✓ New host '$HOSTNAME' created successfully"

          # Ask if user wants to edit the configuration
          echo "Would you like to edit the default.nix configuration file now?"
          EDIT_CONFIG=$(echo -e "Yes\nNo" | ${getExe gum} choose)

          if [ "$EDIT_CONFIG" = "Yes" ]; then
            echo "Opening ''${HOST_DIR}/default.nix in nano..."
            ${getExe nano} "''${HOST_DIR}/default.nix"
            echo "✓ Configuration file edited"
          fi
        else
          HOSTNAME="$SELECTION"
          echo "✓ Selected existing host: $HOSTNAME"
        fi

        echo "================================"
        echo "Installation setup complete!"
        echo "Host: $HOSTNAME"
        echo "Configuration directory: $TARGET_DIR"
        echo ""

        # Ask if user wants to proceed with installation
        echo "Would you like to proceed with the NixOS installation now?"
        PROCEED_INSTALL=$(echo -e "Yes\nNo" | ${getExe gum} choose)

        if [ "$PROCEED_INSTALL" = "Yes" ]; then
          echo "Starting NixOS installation..."
          ${getExe nixos-install} --flake "$TARGET_DIR#$HOSTNAME"
          echo "✓ Installation completed!"
        else
          echo "Installation not started. To install later, run:"
          echo "  nixos-install --flake $TARGET_DIR#$HOSTNAME"
        fi

        echo "================================"
  ''
