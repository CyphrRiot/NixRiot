{ config, lib, pkgs, inputs, ... }:
let
  crush = inputs.nixpkgs-latest.legacyPackages.${pkgs.stdenv.hostPlatform.system}.crush;
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
