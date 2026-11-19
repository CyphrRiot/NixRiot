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
        Install the desktop application set (editors, media, office, backup).
        Turn off for the live installer image, which only needs the desktop and
        the installer.
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
        Install the word processor and spreadsheet (AbiWord and Gnumeric). Off
        by default; the rest of the office set (zathura, Thunar, file-roller)
        is always installed.
      '';
    };

    npu = lib.mkEnableOption "Intel NPU support (driver, firmware, Level Zero)";

    plymouth = lib.mkEnableOption "the NixRiot boot splash (Plymouth)";

    autologin = lib.mkEnableOption "automatic login into the desktop session";

    plymouthLogo = lib.mkOption {
      type = lib.types.path;
      default = pkgs.runCommand "nixriot-plymouth-blank-logo" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
        magick -size 1x1 xc:none PNG:"$out"
      '';
      description = ''
        PNG drawn as the Plymouth logo on the splash. Defaults to a blank 1x1
        image so nothing overlays the artwork; point it at a NixRiot logo PNG
        to show one (transparent background, roughly square).
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

    boot.consoleLogLevel = 7;
    boot.zfs.forceImportRoot = false;

    # The graphical-desktop profile turns this on by default; it pulls
    # speech-dispatcher and about 270 MB of mbrola voices.
    services.speechd.enable = false;

    # lid-close suspend is logind's, not ours: closing the lid suspends unless
    # an external display is attached, because more than one connected display
    # counts as "docked" and HandleLidSwitchDocked is ignore. That is what keeps
    # a laptop on HDMI usable with the lid shut. Stated explicitly so a future
    # logind default cannot quietly change it. The lock runs first, from
    # hypridle's before_sleep_cmd.
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
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

    hardware.cpu.intel.npu.enable = cfg.npu;

    networking.hostName = cfg.hostName;
    time.timeZone = "UTC";
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
