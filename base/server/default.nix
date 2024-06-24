{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}: {
  services.openssh.enable = true;

  # Linode Specific Configuration
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.usePredictableInterfaceNames = false;
}
