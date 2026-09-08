# CONTEXT

Why the OOM module looks the way it does. It covers `default.nix` — the
earlyoom thresholds, the `extraArgs` shape, and the systemd-oomd slice around
`nix-daemon`.

## earlyoom is the only guard that works once the box is thrashing

It polls free RAM *and free swap* from userspace and SIGTERMs the largest
process. The kernel OOM killer never fires at all here — 31G of swap means it
always has somewhere to page to — and `systemd-oomd` needs 30s of sustained
cgroup PSI plus enough CPU to act on it, which is exactly what a thrashing
machine does not have.

## freeSwapThreshold has to be high

Swap here is roughly the size of RAM. earlyoom acts only when free memory AND
free swap are both under their thresholds, so with 31G of swap a 10% swap floor
means waiting until 28G has already been paged out — long past the livelock.
Hence `freeSwapThreshold = 50` / `freeSwapKillThreshold = 25` rather than the
usual defaults.

## extraArgs and escapeShellArgs

`services.earlyoom.extraArgs` goes through `lib.escapeShellArgs`, so a flag and
its value must be separate list entries. `"--prefer '^(x)$'"` written as one
string arrives as a single argv and earlyoom fails to start.

## ManagedOOMSwap on the nix-daemon slice

Without `ManagedOOMSwap = "kill"`, `oomctl` reports an empty
"Swap Monitored CGroups" list and oomd's 90%-swap-used rule applies to nothing
at all.

## MemoryHigh / MemoryMax on nix-daemon

A hard bound on the rebuild. Nothing capped `nix-daemon` before
(`MemoryMax=infinity`), so a runaway eval or a wide parallel build could take
the whole 31G and livelock the desktop. `MemoryHigh` throttles it into reclaim
first; `MemoryMax` kills it and leaves ~17G for the session instead of taking
the machine down.

## oomd on user slices

`enableUserSlices` lets oomd guard desktop apps too, not just `nix-daemon`.
Without it a leaking app can fill swap and thrash the whole session unchecked.
