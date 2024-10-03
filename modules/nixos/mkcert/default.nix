{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "mkcert";
  namespace = "features";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    rootCA = {
      enable = mkEnableOption "Enable mkcert root CA certificate.";
      users = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          List of users to load the root CA certificate for mkcert.
        '';
      };
      path = mkOption {
        type = types.str;
        default = ".local/share/mkcert/rootCA.pem";
        description = ''
          Location of the root CA relative to the user's home directory.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.mkcert
      (pkgs.writeShellScriptBin "mkcert-dev" ''
        domain=$1

        if [ -z "$2" ]; then
          # If the second argument is empty, set it to the current working directory
          directory=$(pwd)
        else
          # Use the provided second argument
          directory="$2"
        fi

        # Generate certificate
        ${pkgs.mkcert}/bin/mkcert -key-file "''${directory}/''${domain}.key" -cert-file "''${directory}/''${domain}.crt" "localhost" "''${domain}" "*.''${domain}"
      '')
    ];

    security.pki.certificateFiles = mkIf cfg.rootCA.enable (lists.forEach cfg.rootCA.users (user: "${config.users.users.${user}.home}/${user}/${cfg.rootCA.path}"));
  };
}
