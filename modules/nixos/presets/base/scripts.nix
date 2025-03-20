{
  pkgs,
  flake,
  ...
}: [
  (pkgs.writeScriptBin "nixos-upgrade" ''
    #!/usr/bin/env bash

    # Function to prompt for commit message with a default
    get_commit_message() {
        local default_message="Updated config files"
        read -p "Enter commit message [''${default_message}]: " commit_message
        echo "''${commit_message:-''$default_message}"
    }

    # Function to prompt for the nh os command with a default
    get_nh_os_command() {
        local default_command="switch"
        local valid_commands=("switch" "boot" "test")
        local input_command

        while true; do
            read -p "Enter nh os command (switch/boot/test) [''${default_command}]: " input_command
            input_command=''${input_command:-''$default_command}

            if [[ " ''${valid_commands[*]} " == *" ''$input_command "* ]]; then
                echo "''$input_command"
                return
            else
                echo "Invalid command. Please enter one of the following: switch, boot, test."
            fi
        done
    }

    # Check if the current directory is a Git repository
    if ${pkgs.git}/bin/git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "This is a Git repository."

        # Check for unstaged changes
        if ! ${pkgs.git}/bin/git diff-index --quiet HEAD --; then
            echo "Unstaged changes detected. Adding and committing changes."

            # Add all changes
            ${pkgs.git}/bin/git add .

            # Get the commit message from the user with a default
            commit_message=''$(get_commit_message)

            # Commit changes with the user-provided or default message
            ${pkgs.git}/bin/git commit -m "''$commit_message"
        else
            echo "No unstaged changes detected."
        fi
    else
        echo "This is not a Git repository."
    fi

    # Get the nh os command from the user with a default
    nh_os_command=$(get_nh_os_command)

    # Run the command nh os switch
    ${pkgs.nh}/bin/nh os "$nh_os_command"
  '')
  (pkgs.writeShellScriptBin "dev-shell" ''
    if [ ''$# -gt 0 ]; then
        nix develop path:"${flake}#''$@"
    else
        nix develop path:''$@
    fi
  '')
  (pkgs.writeShellScriptBin "generate-cert" ''
    domain=$1

    if [ -z "$2" ]; then
    # If the second argument is empty, set it to the current working directory
    directory="$HOME/.local/share/mkcert"
    else
    # Use the provided second argument
    directory="$2"
    fi

    # Generate certificate
    ${pkgs.mkcert}/bin/mkcert -key-file "''${directory}/certs/''${domain}.key" -cert-file "''${directory}/certs/''${domain}.crt" "localhost" "''${domain}" "*.''${domain}"
  '')
  (pkgs.writeShellScriptBin "tmux-session" ''
    SELECTED_PROJECTS=$(tmuxinator list -n |
        tail -n +2 |
        fzf --prompt="Project: " -m -1 -q "$1")

    if [ -n "$SELECTED_PROJECTS" ]; then
        # Set the IFS to \n to iterate over \n delimited projects
        IFS=$'\n'

        # Start each project without attaching
        for PROJECT in $SELECTED_PROJECTS; do
            tmuxinator start "$PROJECT" --no-attach # force disable attaching
        done

        # If inside tmux then select session to switch, otherwise just attach
        if [ -n "$TMUX" ]; then
            SESSION=$(tmux list-sessions -F "#S" | fzf --prompt="Session: ")
            if [ -n "$SESSION" ]; then
                tmux switch-client -t "$SESSION"
            fi
        else
            tmux attach-session
        fi
    fi
  '')
  (pkgs.writeShellScriptBin "odiff" ''
    # Function to convert GitHub URL to raw content URL
    github_to_raw() {
        # Replace 'github.com' with 'raw.githubusercontent.com' and remove '/blob/'
        echo "$1" | ${pkgs.gnused}/bin/sed -e 's/github\.com/raw.githubusercontent.com/' -e 's/\/blob\//\//'
    }

    # Check if the correct number of arguments are provided
    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 <online_file_url> <local_file>"
        exit 1
    fi

    # Assigning arguments to variables
    online_file_url=$1
    local_file=$2

    # Remove the first two arguments from the list
    shift 2

    # Check if the URL is from GitHub
    if [[ "$online_file_url" == *"github.com"* ]]; then
        online_file_url=$(github_to_raw "$online_file_url")
    fi

    # Downloading the online file
    temp_file=$(mktemp)
    ${pkgs.wget}/bin/wget -q -O "$temp_file" "$online_file_url"

    # Check if the download was successful
    if [ ! -f "$temp_file" ]; then
        echo "Failed to download the online file."
        exit 1
    fi

    # Comparing the downloaded file with the local file
    ${pkgs.colordiff}/bin/colordiff "''$@" "$temp_file" "$local_file"

    # Cleaning up temporary file
    rm "$temp_file"
  '')
  (pkgs.writeShellScriptBin "search-package-files" ''
    # Check if at least one argument (the search string) is provided
    if [ "$#" -lt 1 ]; then
        echo "Usage: $0 <search-string> [search-path]"
        exit 1
    fi

    # Store the search string
    search_string="$1"

    # Store the search path; default to root if not provided
    search_path="''${2:-/}"

    # Check if the provided path is a valid directory
    if [ ! -d "$search_path" ]; then
        echo "Error: '$search_path' is not a valid directory."
        exit 1
    fi

    # Define an array of paths to exclude
    exclude_paths=(
        "/nix"
        "/persist"
        "/sys"
        "/proc"
        "/run"
    )

    # Create the find command's prune arguments
    prune_args=""
    for path in "''${exclude_paths[@]}"; do
        prune_args+=" -path $path -o"
    done

    # Remove the last ' -o' from the arguments
    prune_args="''${prune_args% -o}"

    # Perform the search with sudo
    sudo find "$search_path" \( $prune_args \) -prune -o -name "$search_string" -exec sh -c '
        for filepath; do
            if [ -d "$filepath" ]; then
                echo "Directory: $filepath"
            elif [ -f "$filepath" ]; then
                echo "File: $filepath"
            else
                echo "Unknown: $filepath"
            fi
        done
    ' sh {} + 2>/dev/null
  '')
]
