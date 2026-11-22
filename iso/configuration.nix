{ modulesPath, lib, pkgs, inputs, ... }:
let
  nixriot-install = import ../installer { inherit pkgs; };

  installerSession = (pkgs.writeShellScriptBin "nixriot-installer-session" ''
    if [ "$(tty 2>/dev/null)" != "/dev/tty1" ]; then
      exec ${pkgs.bashInteractive}/bin/bash -l
    fi
    /run/wrappers/bin/sudo ${nixriot-install}/bin/nixriot-install
    status=$?
    echo
    echo "The installer exited with status $status without rebooting."
    echo "Dropping to a shell."
    exec ${pkgs.bashInteractive}/bin/bash -l
  '') // {
    shellPath = "/bin/nixriot-installer-session";
  };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
    ../modules/nixriot.nix
  ];

  nixriot = {
    enable = true;
    user = "nixos";
    desktop.enable = false;
    apps = false;
    ocr = false;
  };

  users.users.nixos = {
    shell = installerSession;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "uinput"
    ];
  };

  boot.plymouth.enable = lib.mkForce false;
  boot.kernelParams = lib.mkForce [ "console=tty0" "console=ttyS0,115200n8" "nomodeset" ];
  boot.consoleLogLevel = lib.mkForce 7;

  environment.etc."nixriot".source = lib.cleanSource ../.;

  # Netinstall with a head start: the flake inputs are carried so the flake
  # evaluates offline, and the heaviest parts of the installed system are
  # pre-seeded so nixos-install downloads less. Anything not listed here comes
  # from cache.nixos.org. The machine inherits this flake's nixpkgs pin, so the
  # pre-seeded store paths are byte-identical to the ones the install wants.
  isoImage.storeContents = [
    inputs.nixpkgs.outPath
    inputs.home-manager.outPath

    pkgs.mesa
    pkgs.firefox
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtmultimedia
    pkgs.helix
    pkgs.gvfs
    pkgs.hyprland
    pkgs.quickshell
    pkgs.transmission_4-gtk
    pkgs.mpv
    pkgs.gurk-rs
    pkgs.rclone
    pkgs.restic
    pkgs.zathura
    pkgs.gnome-text-editor
    pkgs.foot
    pkgs.fish
    pkgs.git
    pkgs.noto-fonts-cjk-sans
    pkgs.kora-icon-theme
    pkgs.bibata-cursors
  ];

  image.baseName = lib.mkForce "NixRiot";

  # Better ratio than zstd -19; slower build.
  isoImage.squashfsCompression = lib.mkForce "xz -Xdict-size 100%";

  environment.systemPackages = with pkgs; [
    git
    vim
    gptfdisk
    parted
    dosfstools
    e2fsprogs
    cryptsetup
    util-linux
    nixriot-install
  ];

  boot.loader.grub.memtest86.enable = lib.mkForce false;
}
