{ ... }:
{
  imports = [
    ./fish.nix
    ./helix.nix
    ./crush.nix
    ./xdg.nix
    ./gtk.nix
    ./panacea.nix
  ];

  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "26.05";
}
