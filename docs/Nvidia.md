# NVIDIA support plan

Status: not supported today. This is the plan for the hybrid ThinkPad test case,
not a commitment to fleet support.

## Why it is out of scope today

NixRiot targets Intel and AMD GPUs. `hardware.graphics` is enabled and the
desktop runs on Mesa. NVIDIA needs the proprietary driver for anything beyond
basic nouveau, and Hyprland plus Quickshell on NVIDIA is the usual source of
suspend, explicit-sync and multi-monitor defects. The README already says
NVIDIA is unsupported and untested.

## What a hybrid ThinkPad actually needs

Most X1 Carbon NVIDIA models are hybrid: Intel GPU drives the panel, NVIDIA is
off unless asked. Two distinct tests:

1. **Intel only.** Leave the NVIDIA card idle, do not enable `hardware.nvidia`.
   This proves the desktop works on that laptop. It does not test NVIDIA.
2. **NVIDIA enabled.** This is the real work, and it is untested territory.

## Intel-only test

No config change. Confirm the desktop session uses the Intel GPU:

```sh
glxinfo -B 2>/dev/null | rg -i "device|renderer"
```

If Hyprland and the pill run, the laptop is supported as an Intel machine. The
NVIDIA card stays idle and consumes power unless it is powered down
(`hardware.nvidia.prime.offload.enable` is part of path 2).

## NVIDIA path

Options, all opt-in through a future `nixriot.nvidia` module:

```nix
nixriot.nvidia.enable = true;
```

which would set:

```nix
hardware.nvidia = {
  modesetting.enable = true;
  open = true;                  # Turing and newer
  package = config.boot.kernelPackages.nvidiaPackages.stable;
  powerManagement.enable = true;
  prime.offload.enable = true;  # hybrid: render on NVIDIA on demand
};
boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
boot.kernelParams = [ "nvidia-drm.modeset=1" ];
```

Sizes, all from `cache.nixos.org`, nothing from NVIDIA's site:

- proprietary kernel modules plus userland: roughly 300-500 MB installed,
- open modules: similar,
- GSP firmware: tens of MB, already inside `linux-firmware`,
- 32-bit compatibility libraries: skip, they add a few hundred MB.

None of this is pre-seeded in the ISO, and it must not be: the image is already
at 1.97 GiB against GitHub's 2 GiB limit.

## Why this is a project, not a checkbox

- `nvidia-drm.modeset=1` is required for Wayland; without it the session does
  not start.
- Plymouth needs the NVIDIA modules and firmware in the initrd, or the LUKS
  prompt returns to the black-screen problem on that hardware.
- Suspend and resume on hybrid laptops depend on `powerManagement` and the
  runtime PM setup; these fail silently and look like a hang.
- Hyprland on NVIDIA needs explicit sync and often `env = LIBVA_DRIVER_NAME`
  tuning; Quickshell has its own GL requirements.
- The kernel is pinned per release; a driver update can break the session on
  machines we cannot test.

## Testing plan

1. Intel-only on the friend's X1. Record `glxinfo -B`, suspend, lid, external
   display.
2. NVIDIA enabled, open modules, Wayland session. Check: session starts, pill
   renders, suspend and resume, LUKS prompt on the splash, external display.
3. Repeat on the proprietary modules if the open ones fail.
4. Only then decide whether `nixriot.nvidia` ships as an option, and never as a
   default.

## Decisions

- Keep NVIDIA out of the default image. It is a per-machine option at most.
- Open kernel modules first; proprietary only if the card predates Turing or
  the open ones fail.
- If the friend's laptop works Intel-only, that is a supported configuration
  and the README should say so explicitly.
