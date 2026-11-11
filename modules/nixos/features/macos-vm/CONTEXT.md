# macos-vm

A macOS guest for testing Safari/WebKit. `backend = "container"` is
[dockur/macos](https://github.com/dockur/macos) (QEMU/KVM in a container,
viewed in a browser); `quickemu` is a plain local VM through
`quickget`/`quickemu`. Both take the same codename for `release`, which is why
the enum is the intersection of what each accepts (dockur: catalina–tahoe,
quickget: mojave–tahoe).

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
(`macos-vm-image.service`) instead of pulling it. Bump `rev` by hand, and switch
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
`dostov-dev` pins that release. A fresh install also needs `METAL_ERROR_MODE`
set from Recovery once, or the desktop never comes up. See the reims-vgpu README.

## Host

`ignore_msrs` is on for both backends. macOS reads MSRs that KVM does not
emulate. quickemu warns about this and offers `--ignore-msrs-always`, which
writes to `/etc/modprobe.d`, so it cannot work on NixOS. It is a kvm
module option, so it takes effect only after a reboot or a kvm reload.
