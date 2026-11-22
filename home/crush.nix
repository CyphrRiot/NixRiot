{ pkgs, lib, inputs, nixriotApps ? true, ... }:
let
  crush = inputs.nixpkgs-latest.legacyPackages.${pkgs.stdenv.hostPlatform.system}.crush;
in
{
  home.packages = lib.optionals nixriotApps [ crush ];
}
