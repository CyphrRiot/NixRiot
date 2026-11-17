{ modulesPath, lib, pkgs, ... }:
let
  nixriot-install = import ../installer { inherit pkgs; };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares.nix"
  ];

  environment.etc."nixriot".source = lib.cleanSource ../.;

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

  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  users.users.nixos.extraGroups = [ "wheel" "networkmanager" ];
}
