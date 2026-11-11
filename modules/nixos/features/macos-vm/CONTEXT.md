# macos-vm

A macOS guest for testing Safari/WebKit. `backend = "container"` is
[dockur/macos](https://github.com/dockur/macos) (QEMU/KVM in a container,
viewed in a browser); `quickemu` is a plain local VM through
`quickget`/`quickemu`. Both take the same codename for `release`, which is why
the enum is the intersection of what each accepts (dockur: catalina–tahoe,
quickget: mojave–tahoe).

## Instances

`instances.<name>` exists so a known-good install survives trying another
release: each one gets its own `macos-<name>` volume and unit. dockur would
have shared a volume without clobbering, since it keeps each version's disk
under a `<VERSION>/` subdirectory. But one container can run only one
`VERSION` at a time, and separate units let both run at once. `display`
offsets the published ports (5900/8006 + display) because the containers all
listen on the same ports internally. It has no default, so two instances
can't silently collide, and an assertion rejects duplicates.

The first install lived in a single `macos-vm` volume. It was moved into
`macos-tahoe` by renaming the directory as root, which copies nothing.

Without a GPU, Sequoia's install looked hung at the end: the progress bar sat
full for 15+ minutes with all vCPUs at 100% and no disk I/O. A QEMU
`system_reset` from the monitor booted it straight into Setup Assistant, with
the install intact. The guest reaches the host at the podman gateway,
`10.88.0.1`, so a dev server must bind `0.0.0.0`. That was verified from
Safari.

## GPU

macOS has no driver for any NVIDIA card newer than Kepler, and the i9-14900F
has no iGPU, so VFIO passthrough would need a second, macOS-supported AMD card.
The only option that works here is Reims vGPU: a QEMU device that
macOS's built-in `AppleParavirtGPU` driver talks to, which translates Metal to
Vulkan on the host. dockur wires it up behind `GPU=Y`, so `gpu` is
container-only.

Upstream dockur added Reims on master (2026-09-28), but the newest published
image, v3.12 from 2026-08-21, predates it. That image has no `vulkaninfo`
and no Reims ROM. So the module builds the image from a pinned commit
(`macos-vm-image.service`, using the `fetchFromGitHub` source as the build
context) instead of pulling it. Bump `rev` by hand, and switch
back to the registry image once a release includes it.

NVIDIA's Vulkan needs two things the CDI spec does not provide on NixOS. The
spec mounts the driver libraries but not the ICD manifest, so the Debian image
only finds Mesa ICDs and Vulkan enumerates no GPU. Mounting the manifest is not
enough on its own, because `libGLX_nvidia.so.0` then fails with `libXext.so.6:
cannot open shared object file`: its RUNPATH points into `/nix/store`. Mounting
the store read-only fixes both. With that in place, `vulkaninfo` inside the image
reports the RTX 4060 with `storageBuffer8BitAccess` and
`shaderOutputViewportIndex`, the two features dockur checks for.

`--userns=host` is only there for `/dev/udmabuf` (root:kvm 0660), which Reims
uses to hand guest memory to the GPU. A root mapped by `settings.userns = "auto"`
cannot open it.

Reims has only been tested upstream with x86 guests on macOS 26 (tahoe), which is why
`dostov-dev` pins that release.

Under Reims, macOS also needs `METAL_ERROR_MODE=5` in
`/Library/Preferences/.GlobalPreferences` before its first desktop. Without it
the icon service crashes and the desktop never comes up. On the first try,
Setup Assistant flashed blank, restarted, and then hung on a spinner at
"Data & Privacy". Setting the preference is a manual step from Recovery
Terminal, as the reims-vgpu README describes. dockur hides OpenCore's picker,
and with it the Recovery entry, unless `PICKER=Y` is set. That is what the
`picker` option does.

Automating it was tried and rolled back. dockur's unreleased unattended install
(`MANUAL=N`) runs a root LaunchDaemon on first boot, and patching that daemon
to write the preference looked like the clean fix. But the unattended mode
itself fails on the Tahoe recovery image. Its byte patch of the DMG finds no
anchor (`Expected exactly one rc.cdrom.sh bootstrap, found 0`), so the
container exits 34 before QEMU starts. `Restart=on-failure` then loops,
downloading the recovery image again on every attempt. Revisit once upstream's
unattended mode works on Tahoe.

Even with the preference set, Reims was not usable on this host (RTX 4060,
driver 615.78, dockur 16a5b47, macOS 26.7.3). Setup Assistant got further,
then the guest kernel panicked twice, 45-60s after boot. On a later boot it
hung: the frame froze, all vCPUs sat at 100%, and keys sent through QEMU's
monitor did nothing. So `dostov-dev` runs without `gpu`. Try again after a
Reims or dockur bump. The panic reports are in the guest's
`/Library/Logs/DiagnosticReports/*.panic`.

## Launcher

`macos-vm <instance>` starts its unit and waits until QEMU's VNC port accepts a
connection; podman publishes the port before QEMU listens. If the unit dies
while it waits, it stops and sends a notification. Then it opens
remote-viewer, from virt-viewer. TigerVNC came first, but it cannot scale; its
only option, `RemoteResize`, asks the guest for a new resolution, and macOS
ignores that, so a window smaller than 1920x1080 grew scrollbars.
remote-viewer scales the framebuffer to fit the window.
A polkit rule lets `wheel` start and stop that one unit with no prompt, so
the desktop entry works without a terminal.

`macos-vm <instance> type '<text>'` (or text on stdin) exists because nothing else gets
text into the guest. QEMU's VNC clipboard needs a guest agent, and macOS has
none. `wtype` into TigerVNC types garbage: it uploads its own keymap, and
Xwayland maps those keycodes through the real layout, so it typed
`1234567890-=qwer…`. `sendkeys.py` drives the HMP monitor socket dockur
already opens inside the container, one `sendkey` per character, assuming a US
layout. The monitor socket lives on the container's tmpfs, so the command goes
through the engine's `exec`, and for podman through the rootful socket,
because the CLI user's own podman is a separate rootless namespace.

## Host

`ignore_msrs` is on for both backends. macOS reads MSRs that KVM does not
emulate. quickemu warns about this and offers `--ignore-msrs-always`, which
writes to `/etc/modprobe.d`, so it cannot work on NixOS. It is a kvm
module option, so it takes effect only after a reboot or a kvm reload.
