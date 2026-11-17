{ modulesPath, lib, pkgs, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares.nix"
  ];

  environment.etc."nixriot".source = lib.cleanSource ../.;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  users.users.nixos.extraGroups = [ "wheel" "networkmanager" ];
}
