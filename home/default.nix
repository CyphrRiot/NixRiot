{ ... }:
{
  imports = [
    ./fish.nix
    ./helix.nix
    ./crush.nix
    ./xdg.nix
    ./panacea.nix
  ];

  home.username = "riot";
  home.homeDirectory = "/home/riot";
  home.stateVersion = "26.05";
}
