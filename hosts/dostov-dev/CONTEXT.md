# CONTEXT

The `dostov-dev` workstation. Covers the host's `nix.settings` build limits and
the niri login layout in `home.nix`.

## Build parallelism is capped by RAM, not by core count

32 threads but only 31G of RAM — about 1G per thread, which is lean for
compiling. `max-jobs = 12` with `cores = 0` let nix run 12 derivations at once
and hand each one all 32 cores, so the worst case was hundreds of concurrent
compilers on a box that cannot feed them. `4 × 8` saturates the CPU exactly
once without the memory multiplier.

## The login layout needs a script for the ghostty half

Login layout: vivaldi on Browser (DP-1); legcord + ghostty stacked 50/50 in one
column on Communication (DP-2). The window rules in `home.nix` place vivaldi and
legcord — a rule can pin a window to a workspace but cannot drop it into an
existing column, so only the ghostty half needs the `loginLayout` script.

## The Xerox needs a vendored PPD and the raw PDL port

The WorkCentre 6605DN (mDNS `XRX9C934E127ECD.local`, 192.168.5.20) is a 2013
PostScript device and none of the obvious drivers fit it:

- `model = "everywhere"` cannot work. Its mDNS TXT advertises
  `pdl=application/postscript,application/pdf,application/vnd.hp-PCL,application/vnd.hp-PCLXL`
  with no `image/urf` or `image/pwg-raster`, and `driverless` reports
  `IPP_STATUS_ERROR_VERSION_NOT_SUPPORTED` on IPP 2.0 — IPP Everywhere needs both.
- Nothing in nixpkgs carries a PPD for it: `foomatic-db-ppds`,
  `foomatic-db-nonfree` and `gutenprint` were all searched and have no 6605 or
  Phaser 6600 entry. Xerox ships no Linux PPD either — the file only exists
  inside their Windows `.exe` installers.
- `driverless cat` will synthesise a fallback PPD, but it comes out as
  "Xerox Printer" with `Printer did not supply page size info via IPP`: no
  duplex, no trays, no colour correction.

So `xerox-wc6605dn.ppd` is vendored here. It is Xerox's own `xr6605dn.ppd`
(Copyright 2009-2010 Xerox Corporation), passes `cupstestppd -q` clean, and
carries the full option set — Duplex, InputSlot, MediaType, Collate,
OutputMode, XRXColor. Its defaults are already Letter and `DuplexNoTumble`, so
`ppdOptions` would only restate them.

The queue uses `socket://…:9100`, not `ipp://…/ipp/`. `ipptool` gets
`RECEIVED: 0 bytes` from this firmware's IPP port at both 2.0 and 1.1, while
the raw PDL port is advertised over `_pdl-datastream._tcp` and was verified by
piping PostScript at it and watching the SNMP lifetime page counter
(`1.3.6.1.2.1.43.10.2.1.4.1.1`) advance. The cost is that CUPS gets no job or
supply status back.
