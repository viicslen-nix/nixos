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
      if [[ $# -eq 1 ]]; then
          selected=$1
      else
          selected=$(find ~/Development -mindepth 1 -maxdepth 1 -type d | ${pkgs.fzf}/bin/fzf)
      fi

      if [[ -z $selected ]]; then
          exit 0
      fi

      selected_name=$(basename "$selected" | tr . _)
      tmux_running=$(pgrep tmux)

      if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
          ${pkgs.tmux}/bin/tmux new-session -s $selected_name -c $selected
          exit 0
      fi

      if ! ${pkgs.tmux}/bin/tmux has-session -t=$selected_name 2> /dev/null; then
          ${pkgs.tmux}/bin/tmux new-session -ds $selected_name -c $selected
      fi

      ${pkgs.tmux}/bin/tmux switch-client -t $selected_name
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
