{ config, lib, pkgs, ... }:
let
  crush = import ../pkgs/crush.nix { inherit pkgs; };
in
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.apps) {
    environment.systemPackages = with pkgs; [
      helix
      gnome-text-editor
      crush
      git
    ] ++ lib.optionals config.nixriot.claude [ claude-code ];
  };
}
