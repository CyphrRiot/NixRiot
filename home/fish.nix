{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
  ];

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    PAGER = "less";
  };
}
