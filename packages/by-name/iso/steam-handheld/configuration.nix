{inputs, pkgs, lib, ...}: {
  imports = [
    inputs.jovian.nixosModules.default
  ];

  hardware.amdgpu.initrd.enable = false;
  boot.kernelParams = [ "quiet" ];
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;
    "kernel.nmi_watchdog"        = 0;
    "kernel.sched_bore"          = "1";
  };

  boot.initrd = {
    systemd.enable   = true;
    kernelModules    = [ ];
    verbose          = false;
  };

  jovian.hardware.has.amd.gpu = true;
}
