# CONTEXT

Why this module rewraps `chromium`, `google-chrome` and `brave`, exports
`chromiumFeatures`, and sets `MOZ_DISABLE_RDD_SANDBOX`. Everything below was
measured on `dostov-dev` (RTX 4060, open driver 615.71.09, niri, Wayland); the
test drove each browser over CDP / WebDriver BiDi in a throwaway profile and
watched `nvidia-smi --query-gpu=utilization.decoder` during decode.

It is an overlay rather than a per-program option because `pkgs.chromium`
reaches the desktop through several modules (`webapps`, the browser-harness
headless service, hyprland scratchpads), none of which go through
`programs.chromium` — on `dostov-dev` that option wraps Vivaldi. Vivaldi has its
own wrapper in its home-manager module, which reads `chromiumFeatures` from
here.

## Only the last `--enable-features` counts

Chromium keeps the last `--enable-features=` it is given and drops the rest
(verified: putting the VA-API features ahead of another `--enable-features`
left decode in software). The nixpkgs wrappers for chromium and google-chrome
pass `--enable-features=WaylandWindowDecorations` (on Wayland), and Brave's
passes `AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,WaylandWindowDecorations`.
All three put `commandLineArgs` *after* those, so ours wins — which is why each
`features` list restates the wrapper's own, or they would be lost.

It must stay `.override { commandLineArgs }`. An outer `symlinkJoin` wrapper
was tried and broke evaluation: nixpkgs' electron builds from
`chromium.override { … }).mkDerivation`, and a `symlinkJoin` has neither.

## VA-API video decode

All Chromium-based browsers decode in software by default here — Chromium
skips VA-API on NVIDIA (`Should skip nVidia device named: nvidia-drm`).
`VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,AcceleratedVideoDecodeLinuxGL`
brings up `nvidia-vaapi-driver` for H.264, VP9 and AV1 in Chromium, Chrome,
Brave and Vivaldi, with NVDEC at ~94% under load. No `LIBVA_DRIVER_NAME` or
`NVD_BACKEND` is needed: libva maps `nvidia-drm` to the driver itself.

Firefox (Zen) needs both the prefs `media.ffmpeg.vaapi.enabled` and
`media.hardware-video-decoding.force-enabled` (set in the zen-browser module)
*and* `MOZ_DISABLE_RDD_SANDBOX=1`; either alone stays in software. That
variable disables the sandbox around Firefox's media decoder process — the
accepted cost of NVDEC in Firefox with this driver.

## WebGPU needs ANGLE on Vulkan

Chromium 153 and Chrome 154 report WebGPU "enabled" in `chrome://gpu`, yet
`navigator.gpu.requestAdapter()` returns `null`. On Wayland Chromium composites
through ANGLE-on-GL, so Dawn has to bring up Vulkan itself inside the already
sandboxed GPU process, and the sandbox keeps it from the NVIDIA ICD.
`--disable-gpu-sandbox` proves it but costs the sandbox. `--use-angle=vulkan`
loads the NVIDIA Vulkan driver before the sandbox engages; Dawn then finds it,
with the sandbox on and no `--enable-unsafe-webgpu`. It needs no extra
features. The `Vulkan` feature is the wrong knob: it is rejected on Wayland
(`'--ozone-platform=wayland' is not compatible with Vulkan`).

Brave 1.95 and Vivaldi 8.3 have no WebGPU fix: `--use-angle=vulkan`,
`--disable-gpu-sandbox`, `--enable-unsafe-webgpu` and `--use-vulkan=native`
all leave them on the SwiftShader fallback adapter. Brave gets no
`--use-angle=vulkan` because it bundles an unpatched `libvulkan.so.1` that
cannot see `/run/opengl-driver`: ANGLE-on-Vulkan kills its GPU process unless
`VK_DRIVER_FILES` points at `nvidia_icd.json`, and even then Dawn finds no
adapter. Vivaldi links nixpkgs' patched loader and fails anyway, so the loader
is not the whole story.

Zen needs no GPU flag for WebGPU: `dom.webgpu.enabled = true` (set in the
zen-browser module) yields a hardware adapter.
