{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.nixriot.enable {
    programs.fish.enable = true;
    programs.fish.generateCompletions = false;
    users.defaultUserShell = pkgs.fish;

    environment.systemPackages = with pkgs; [
      fish
      zoxide
      ripgrep
      fd
      fzf
      btop
      fastfetch
      lsd
      bat
      pv
      jq
      gurk-rs
    ];
  };
}
