{ pkgs, lib, nixriotApps ? true, ... }:
{
  home.packages = lib.optionals nixriotApps [ pkgs.crush ];
}
