# CONTEXT

## Boot chain: firmware → rEFInd → GRUB → kernel

Windows and NixOS share the 256 MB ESP on `nvme1n1`; NixOS lives on btrfs
inside LVM on `nvme0n1`. The firmware's first entry is
`\EFI\refind\refind_x64.efi`, which offers Windows and a "NixOS" entry that
chainloads GRUB at `\EFI\Boot\bootx64.efi` (the removable path, since
`efiInstallAsRemovable = true`). GRUB reads the kernels from LVM.

Why not nixpkgs' `boot.loader.refind`: rEFInd has no LVM driver, so it would
copy every kernel and initrd onto the ESP (~70 MB per generation, so only about
two generations fit), and it deletes anything under `EFI/refind` it didn't
write, theme included. So GRUB stays the loader and `refind.nix` uses
`grub.extraInstallCommands` to write rEFInd's binary, drivers, theme and
`refind.conf` onto the ESP on every rebuild. `vars/`, `icons/` and `tools_x64/`
there are rEFInd's own and left alone.

What broke before: an older GRUB copy at `EFI/NixOS-boot-efi/grubx64.efi`
(from before the removable install) stopped being updated. After a GRUB upgrade
its core no longer matched the modules in `/boot/grub` and dropped to
`grub rescue`. rEFInd scans every directory under `EFI`, so any stale loader
there shows up in the menu; delete it rather than renaming it.

## Suspend: SD card reader kept out of D3cold

The Genesys GL9755 SD reader (`17a0:9755`, `0000:2d:00.0` behind root port
`00:1c.6`) does not survive s2idle when ACPI cuts its power (the port has
`_PR3` power resources): it stays in D3cold, config space reads `0xffffffff`,
and `sdhci_pci` floods the log with "Reset never completed" dumps and WARNs in
`sdhci_suspend_host` on every later suspend — the trace seen on screen after
waking. A PCI remove/rescan or port reset does not bring it back; only a
reboot does. A udev rule sets `d3cold_allowed=0` so it sleeps in D3hot and
keeps power. Blacklisting `sdhci_pci` also stops it but loses the SD slot.
The ACPI `AE_NOT_FOUND` errors at boot and the `spd5118` resume `-6` are
harmless BIOS/sensor noise, not the cause.
