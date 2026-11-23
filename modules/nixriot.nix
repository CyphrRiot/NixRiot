{ lib, config, pkgs, self, ... }:
let
  cfg = config.nixriot;
in
{
  imports = [
    ./desktop/panacea.nix
    ./desktop/theme.nix
    ./desktop/sddm.nix
    ./desktop/plymouth.nix
    ./update.nix
    ./features.nix
    ./apps/shell.nix
    ./apps/editors.nix
    ./apps/media.nix
    ./apps/office.nix
    ./apps/games.nix
    ./crypto/monero.nix
    ./crypto/bitcoin.nix
    ./crypto/glyphriot.nix
    ./crypto/wireguard.nix
    ./security/hardening.nix
    ./security/backup.nix
  ];

  options.nixriot = {
    enable = lib.mkEnableOption "the NixRiot system profile";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixriot";
      description = "Hostname for the installed system.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "user";
      description = "Primary desktop user.";
    };

    desktop.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the NixRiot desktop.";
    };

    crypto = {
      monero = lib.mkEnableOption "the Monero GUI wallet";
      bitcoin = lib.mkEnableOption "Bitcoin Core and Bitcoin Qt";
    };

    media.transmission = lib.mkEnableOption "the Transmission BitTorrent client";

    games = lib.mkEnableOption "the curated OpenRiot game collection";

    apps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the desktop application set (shell and CLI tools, editors,
        media, office, backup). Turn off for the live installer image, which
        only needs the desktop and the installer. Everything here rides in the
        ISO, which is close to GitHub's 2 GiB asset limit.
      '';
    };

    ocr = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install tesseract for the screenshot text feature. It pulls about a
        gigabyte of language data, so it is off by default.
      '';
    };

    office = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install LibreOffice, about 1 GB of closure. Off by default; the rest
        of the office set (zathura, file-roller) is always installed.
      '';
    };

    npu = lib.mkEnableOption "Intel NPU support (driver, firmware, Level Zero)";

    plymouth = lib.mkEnableOption "the NixRiot boot splash (Plymouth)";

    autologin = lib.mkEnableOption "automatic login into the desktop session";

    plymouthLogo = lib.mkOption {
      type = lib.types.path;
      default = ../panacea/panacea/assets/logo-256.png;
      description = ''
        PNG drawn as the Plymouth logo on the splash. Defaults to the Panacea
        mark; point it at another square PNG to change it.
      '';
    };

    fingerprint = {
      enable = lib.mkEnableOption "fingerprint reader support (fprintd)";

      pam = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Add fingerprint auth to login, sudo and polkit. Leave this off until
          `fprintd-enroll` and `fprintd-verify` succeed with the reader, so a
          reader that does not work cannot interfere with password login.
        '';
      };

      tod = {
        enable = lib.mkEnableOption "Touch OEM Driver support for readers that need it";

        driver = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
          description = ''
            ToD driver package for the reader, for example
            `pkgs.libfprint-2-tod1-goodix`. Required when `tod.enable` is set.
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "26.05";

    system.nixos.distroName = "NixRiot";

    system.activationScripts.binbash = ''
      ln -sfn ${pkgs.bashInteractive}/bin/bash /bin/bash
    '';

    boot.consoleLogLevel = 4;
    boot.zfs.forceImportRoot = false;

    # Compressed RAM swap keeps cold pages out of the way without a disk
    # swapfile. The dirty caps stop a large copy, such as an rsync from a USB
    # disk, from accumulating unflushed writes until the whole session stalls.
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };

    # The switch rewrites the user D-Bus configuration every generation, and the
    # reload that follows drops the session bus under running apps, which is
    # enough to abort Chromium and Electron programs. Defer it to the next login.
    systemd.user.services.dbus-broker = {
      reloadIfChanged = lib.mkForce false;
      restartIfChanged = lib.mkForce false;
    };

    boot.kernelParams = [ "quiet" "fbcon=nodefer" "amdgpu.dcdebugmask=0x410" "i915.enable_psr=0" "i915.enable_fbc=0" "i915.enable_dc=0" "xe.enable_psr=0" ];

    # The passphrase prompt is written to the console the initrd runs on. On
    # some Intel panels the firmware framebuffer ignores the partial updates the
    # console makes, so the prompt stays invisible until a key forces a redraw.
    # Loading the display driver here puts the initrd console on i915 instead.
    boot.initrd.kernelModules = [ "i915" ];

    boot.kernel.sysctl = {
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_bytes" = 268435456;
    };

    # The graphical-desktop profile turns this on by default; it pulls
    # speech-dispatcher and about 270 MB of mbrola voices.
    services.speechd.enable = false;

    # Lid handling belongs to the session, not logind. logind starts before the
    # graphical session and suspends the moment it sees a closed lid, which
    # hangs a reboot started with the lid shut. This is not the same as
    # "docked": logind has no concept of connected displays, so an external
    # monitor never made it ignore the lid. The desktop now decides: see
    # panacea/hypr/lua/lid.lua, which suspends when the lid is closed without an
    # external display and leaves the machine awake when one is attached.
    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    # Ship only the firmware a laptop can use. Dropped: whole-ARM-SoC qcom,
    # server NICs (mellanox, netronome, dpaa2, qed, liquidio, cxgb4, bnx2x,
    # sfc, qlogic) and the Marvell Prestera switch ASIC. Kept: every x86
    # Wi-Fi/BT/GPU/audio family, NVIDIA included.
    hardware.enableAllFirmware = lib.mkForce false;
    hardware.enableRedistributableFirmware = lib.mkForce false;
    hardware.wirelessRegulatoryDatabase = true;
    hardware.firmware = lib.mkForce ([
      (pkgs.linux-firmware.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          rm -rf $out/lib/firmware/qcom \
                 $out/lib/firmware/mellanox \
                 $out/lib/firmware/netronome \
                 $out/lib/firmware/dpaa2 \
                 $out/lib/firmware/qed \
                 $out/lib/firmware/liquidio \
                 $out/lib/firmware/cxgb4 \
                 $out/lib/firmware/bnx2x \
                 $out/lib/firmware/sfc \
                 $out/lib/firmware/qlogic \
                 $out/lib/firmware/mrvl/prestera
          # qcom holds the Adreno blobs that root-level symlinks point into, so
          # drop the symlinks the removals left dangling.
          find $out/lib/firmware -xtype l -delete
        '';
      }))
      pkgs.sof-firmware
      pkgs.alsa-firmware
      pkgs.rtl8761b-firmware
      pkgs.ipw2200-firmware
      pkgs.rt5677-firmware
      pkgs.zd1211fw
      pkgs.rtl8192su-firmware
    ] ++ lib.optionals cfg.npu [ pkgs.intel-npu-driver.firmware ]);

    # mkDefault, not a plain assignment: on a machine with an Intel NPU,
    # nixos-generate-config writes `hardware.cpu.intel.npu.enable = true;` into
    # the generated hardware-configuration.nix, and two plain definitions of one
    # option is a hard error that stops nixos-install. A virtual machine has no
    # NPU device, which is why this only ever failed on real hardware.
    hardware.cpu.intel.npu.enable = lib.mkDefault cfg.npu;

    networking.hostName = cfg.hostName;
    system.nixos.label = lib.removeSuffix "\n" (builtins.readFile ../VERSION);
    # Null lets /etc/localtime be set at run time (the pill uses timedatectl).
    # A fixed value here would overwrite it on every rebuild and update.
    time.timeZone = null;
    i18n.defaultLocale = "en_US.UTF-8";

    users.users.${cfg.user} = lib.mkIf cfg.desktop.enable {
      isNormalUser = true;
      group = "users";
      homeMode = "0750";
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "input"
        "uinput"
      ];
    };

    security.sudo.wheelNeedsPassword = lib.mkIf cfg.desktop.enable true;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    services.displayManager.autoLogin = lib.mkIf cfg.autologin {
      enable = true;
      user = cfg.user;
    };

    environment.etc."nixriot-image-revision".text = self.rev or self.dirtyRev or "unknown";

    services.fprintd.enable = lib.mkIf cfg.fingerprint.enable true;
    services.fprintd.enablePam = lib.mkIf cfg.fingerprint.enable cfg.fingerprint.pam;
    services.fprintd.tod.enable =
      lib.mkIf (cfg.fingerprint.enable && cfg.fingerprint.tod.enable) true;
    services.fprintd.tod.driver =
      lib.mkIf (cfg.fingerprint.enable && cfg.fingerprint.tod.enable)
        cfg.fingerprint.tod.driver;

    environment.systemPackages = with pkgs; [
      git
      curl
      rsync
      unzip
      zip
      xz
    ];
  };
}
