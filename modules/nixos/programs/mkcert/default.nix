{
  lib,
  pkgs,
  users,
  config,
  ...
}:
with lib; let
  name = "mkcert";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    rootCA = {
      enable = mkEnableOption "Enable mkcert root CA certificate.";
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

    security.pki.certificateFiles = mkIf cfg.rootCA.enable (map (user: "${config.users.users.${user}.home}/${user}/${cfg.rootCA.path}") (attrNames users));
  };
}
