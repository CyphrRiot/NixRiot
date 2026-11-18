{ nixriotApps ? true, ... }:
{
  programs.helix = {
    enable = nixriotApps;
    defaultEditor = nixriotApps;
  };
}
