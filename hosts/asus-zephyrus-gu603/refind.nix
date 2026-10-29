{
  config,
  lib,
  pkgs,
  ...
}: let
  theme = pkgs.fetchFromGitHub {
    owner = "bobafetthotmail";
    repo = "refind-theme-regular";
    rev = "ed76f1e6d1bfe790ea7333fe5886fa7af126475d";
    hash = "sha256-Qo3/Y1ga1/+joasXilr56lBnc1WUjd1Kubv647pt/qQ=";
  };

  conf = pkgs.writeText "refind.conf" ''
    timeout 20
    use_nvram false
    uefi_deep_legacy_scan false

    # `+` appends; without it the default list (shim tools, bootmgr.efi) is replaced.
    dont_scan_files + \EFI\Boot\bootx64.efi

    menuentry "NixOS" {
        icon \EFI\refind\themes\refind-theme-regular\icons\128-48\os_nixos.png
        loader \EFI\Boot\bootx64.efi
    }

    include themes/refind-theme-regular/theme.conf
  '';
in {
  boot.loader.grub.extraInstallCommands = ''
    PATH=${lib.makeBinPath [pkgs.coreutils]}:$PATH
    dir="${config.boot.loader.efi.efiSysMountPoint}/EFI/refind"
    put() { cp "$1" "$2.tmp" && mv "$2.tmp" "$2"; }

    mkdir -p "$dir/drivers_x64" "$dir/themes"
    put ${pkgs.refind}/share/refind/refind_x64.efi "$dir/refind_x64.efi"
    for f in ${pkgs.refind}/share/refind/drivers_x64/*; do put "$f" "$dir/drivers_x64/$(basename "$f")"; done

    rm -rf "$dir/themes/refind-theme-regular.tmp"
    cp -r --no-preserve=mode ${theme} "$dir/themes/refind-theme-regular.tmp"
    rm -rf "$dir/themes/refind-theme-regular"
    mv "$dir/themes/refind-theme-regular.tmp" "$dir/themes/refind-theme-regular"

    put ${conf} "$dir/refind.conf"
    sync -f "$dir/refind.conf"
  '';
}
