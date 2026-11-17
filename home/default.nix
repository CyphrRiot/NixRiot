{ nixriotUser ? "user", ... }:
{
  imports = [
    ./fish.nix
    ./helix.nix
    ./crush.nix
    ./xdg.nix
    ./gtk.nix
    ./panacea.nix
  ];

  home.username = nixriotUser;
  home.homeDirectory = "/home/${nixriotUser}";
  home.stateVersion = "26.05";
}
