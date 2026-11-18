{ modulesPath, lib, pkgs, inputs, installedSystem, ... }:
let
  nixriot-install = import ../installer { inherit pkgs; };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
    ../modules/nixriot.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Boot straight into the NixRiot desktop. The live user is `nixos`.
  # The application set and OCR are left out: they cost gigabytes and the
  # installer image only needs the desktop and the installer.
  nixriot = {
    enable = true;
    user = "nixos";
    desktop.enable = true;
    apps = false;
    ocr = false;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    inherit inputs;
    panaceaSrc = ../panacea;
    nixriotUser = "nixos";
    nixriotApps = false;
  };
  home-manager.users.nixos = { lib, ... }: {
    imports = [ ../home ];

    # Open the installer in a terminal once Panacea has laid out its config.
    # Hyprland reads the Lua config here, so the autostart goes in the Lua
    # module (custom/autostart.lua), not custom/execs.conf.
    home.activation.nixriotLiveInstaller =
      lib.hm.dag.entryAfter [ "panaceaConfig" ] ''
        run mkdir -p "$HOME/.config/hypr/custom"
        run cat > "$HOME/.config/hypr/custom/autostart.lua" <<'NIXRIOT_LUA'
        hl.on("hyprland.start", function()
          hl.exec_cmd("foot -e sh -c 'sudo /run/current-system/sw/bin/nixriot-install; echo; echo Press Enter to close; read x'")
        end)
        NIXRIOT_LUA
      '';
  };

  users.users.nixos.extraGroups = [
    "wheel"
    "networkmanager"
    "video"
    "audio"
    "input"
    "uinput"
  ];

  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  environment.etc."nixriot".source = lib.cleanSource ../.;

  # Offline install: carry the whole target system closure in the ISO store, so
  # nixos-install needs no network. The flake inputs come along too.
  isoImage.storeContents = [
    installedSystem
    inputs.nixpkgs.outPath
    inputs.home-manager.outPath
    inputs.nixos-generators.outPath
  ];

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

  # Branding and quiet boot come from modules/nixriot.nix.
  boot.loader.grub.memtest86.enable = lib.mkForce false;
}
