{ config, lib, pkgs, ... }:
{
  options.nixriot.crypto.glyphriot =
    lib.mkEnableOption "the GlyphRiot seed-phrase glyph tool";

  config = lib.mkIf (config.nixriot.enable && config.nixriot.crypto.glyphriot) {
    environment.systemPackages = [ (pkgs.callPackage ../pkgs/glyphriot.nix { }) ];
  };
}
