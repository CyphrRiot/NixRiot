{ pkgs, lib, nixriotApps ? true, ... }:
let
  crush = import ../modules/pkgs/crush.nix { inherit pkgs; };
in
{
  home.packages = lib.optionals nixriotApps [ crush ];
}
