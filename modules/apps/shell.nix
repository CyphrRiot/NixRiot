{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.nixriot.enable {
    programs.fish.enable = true;
    users.defaultUserShell = pkgs.fish;

    environment.systemPackages = with pkgs; [
      fish
      starship
      eza
      zoxide
      ripgrep
      fd
      fzf
      btop
      fastfetch
      lsd
      bat
      pv
      tree
      jq
      yq
    ];
  };
}
