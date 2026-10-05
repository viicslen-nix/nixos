{pkgs, ...}: [
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
]
