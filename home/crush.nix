{ pkgs, lib, inputs, nixriotApps ? true, ... }:
let
  crush = (import inputs.nixpkgs-latest {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  }).crush;
in
{
  home.packages = lib.optionals nixriotApps [ crush ];
}
