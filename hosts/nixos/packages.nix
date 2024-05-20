{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # CLI Tools
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

    # GUI Apps
    libreoffice-fresh
    tangram
    endeavour
    drawing
    kooha

    # Scripts
    (pkgs.writeScriptBin "nixos-upgrade" ''
      #!/usr/bin/env bash

      # Function to prompt for commit message with a default
      get_commit_message() {
          local default_message="Updated config files"
          read -p "Enter commit message [''${default_message}]: " commit_message
          echo "''${commit_message:-''$default_message}"
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

      # Run the command nh os switch
      ${pkgs.nh}/bin/nh os switch
    '')
  ];
}
