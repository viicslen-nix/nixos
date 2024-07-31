{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}: {
  # Enable SSH server
  services.openssh.enable = true;

  # Disable printing
  services.printing.enable = false;

  # Linode Specific Configuration
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.usePredictableInterfaceNames = false;
}
