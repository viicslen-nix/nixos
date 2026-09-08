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
