 {
            inputs,
            config,
            lib,
            pkgs,
            ...
          }: let
            # disko
            disko = pkgs.writeShellScriptBin "disko" ''${config.system.build.disko}'';
            disko-mount = pkgs.writeShellScriptBin "disko-mount" "${config.system.build.mountScript}";
            disko-format = pkgs.writeShellScriptBin "disko-format" "${config.system.build.formatScript}";

            # system
            system = self.nixosConfigurations.asus-zephyrus-gu603.config.system.build.toplevel;

            install-system = pkgs.writeShellScriptBin "install-system" ''
              set -euo pipefail

              echo "Formatting disks..."
              . ${disko-format}/bin/disko-format

              echo "Mounting disks..."
              . ${disko-mount}/bin/disko-mount

              echo "Installing system..."
              nixos-install --system ${system}

              echo "Done!"
            '';
          in {
            imports = [
              (import ../../hosts/asus-zephyrus-gu603/disko.nix {
                inherit inputs;
                device = "/dev/nvme0n1";
              })
            ];

            # we don't want to generate filesystem entries on this image
            disko.enableConfig = lib.mkDefault false;

            # add disko commands to format and mount disks
            environment.systemPackages = [
              disko
              disko-mount
              disko-format
              install-system
            ];
          }
