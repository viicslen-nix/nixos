{
  lib,
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
  (pkgs.writeShellScriptBin "tmux-session" ''
    SELECTED_PROJECTS=$(${lib.getExe pkgs.tmuxinator} list -n |
        tail -n +2 |
        fzf --prompt="Project: " -m -1 -q "$1")

    if [ -n "$SELECTED_PROJECTS" ]; then
        # Set the IFS to \n to iterate over \n delimited projects
        IFS=$'\n'

        # Start each project without attaching
        for PROJECT in $SELECTED_PROJECTS; do
            ${lib.getExe pkgs.tmuxinator} start "$PROJECT" --no-attach # force disable attaching
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
