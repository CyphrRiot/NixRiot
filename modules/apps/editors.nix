{ config, lib, pkgs, inputs, ... }:
let
  crush = (import inputs.nixpkgs-latest {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  }).crush;
in
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.apps) {
    environment.systemPackages = with pkgs; [
      helix
      gnome-text-editor
      crush
      git
    ];
  };
}
