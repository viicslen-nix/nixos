{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # CLI Tools
    libsecret
    wget
    curl
    git
    fzf
    lshw
    chezmoi
    lsd
    bat
    ripgrep
    gh
    unzip
    jq
    tmux
    zoxide
    htop
    gcc
    glibc
    glib
    just

    # Scripts
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
  ];
}
