{
  pkgs,
  user,
  ...
}: {
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "dev-shell" ''
      if [ ''$# -gt 0 ]; then
          nix develop path:"/home/${user}/.nix#''$@"
      else
          nix develop path:''$@
      fi
    '')
    (pkgs.writeShellScriptBin "generate-cert" ''
      domain=$1

      if [ -z "$2" ]; then
        # If the second argument is empty, set it to the current working directory
        directory=$(pwd)
      else
        # Use the provided second argument
        directory="$2"
      fi

      # Generate certificate
      ${pkgs.mkcert}/bin/mkcert -key-file "''${directory}/certs/''${domain}.key" -cert-file "''${directory}/certs/''${domain}.crt" "localhost" "''${domain}" "*.''${domain}"

      # Append to ssl.yml
      echo "    - certFile: /etc/traefik/certs/''${domain}.crt" | tee -a ''${directory}/conf/traefik/ssl.yml
      echo "      keyFile: /etc/traefik/certs/''${domain}.key" | tee -a ''${directory}/conf/traefik/ssl.yml
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
  ];
}
