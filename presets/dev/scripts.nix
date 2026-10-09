{pkgs, ...}: [
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
]
