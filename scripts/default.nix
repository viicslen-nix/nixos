{pkgs, ...}: with pkgs;{
  upgrade = {
    description = "Upgrade System";
    exec = (writeShellScriptBin "system-upgrade" ''
      #!${stdenv.shell}

      HOSTNAME=$(hostname)
      USE_HOSTS_DIR=false
      USE_HOSTNAME_ARG=false
      ACTION="switch"

      while getopts "Hh:a:" opt; do
        case ''${opt} in
          H )
            if [ "$USE_HOSTNAME_ARG" = true ]; then
              echo "Options -H and -h cannot be used together."
              exit 1
            fi
            USE_HOSTS_DIR=true
            HOSTS_DIR="./hosts"
            if [ ! -d "$HOSTS_DIR" ]; then
              echo "Error: Hosts directory '$HOSTS_DIR' not found."
              exit 1
            fi
            HOSTNAMES=$(find ''${HOSTS_DIR}/ -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -n 1 basename)
            if [ -z "$HOSTNAMES" ]; then
              echo "Error: No hosts found in '$HOSTS_DIR'."
              exit 1
            fi
            HOSTNAME=$(echo "''${HOSTNAMES}" | ${gum}/bin/gum choose)
            if [ -z "$HOSTNAME" ]; then
              echo "Error: No hostname selected."
              exit 1
            fi
            ;;
          h )
            if [ "$USE_HOSTS_DIR" = true ]; then
              echo "Options -H and -h cannot be used together."
              exit 1
            fi
            USE_HOSTNAME_ARG=true
            HOSTNAME=''${OPTARG}
            ;;
          a )
            ACTION=''${OPTARG}
            ;;
          \? )
            echo "Usage: cmd [-H] [-h hostname] [-a action]"
            exit 1
            ;;
        esac
      done

      echo "=== System Upgrade ==="
      echo "Hostname: ${HOSTNAME}"
      echo "Action: ${ACTION}"
      echo "======================"

      if command -v nh &> /dev/null; then
        nh os ''${ACTION}
      else
        sudo nixos-rebuild ''${ACTION} --flake .#''${HOSTNAME}
      fi
    '');
  };

  update = {
    description = "Update Inputs";
    exec = (writeShellScriptBin "system-update" ''
      #!${stdenv.shell}

      if [ "$#" -eq 0 ]; then
        nix flake update
      else
        for input in "$@"; do
          nix flake lock --update-input ''${input}
        done
      fi
    '');
  };
}
