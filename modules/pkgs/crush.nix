{ pkgs }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "crush";
  version = "0.104.0";

  src = pkgs.fetchurl {
    url = "https://github.com/charmbracelet/crush/releases/download/v0.104.0/crush_0.104.0_Linux_x86_64.tar.gz";
    hash = "sha256-4YZZ6qUDGDyOm7MJMcST0DhN0ooLGMZE44MTUHvCpAU=";
  };

  sourceRoot = "crush_0.104.0_Linux_x86_64";
  installPhase = ''
    install -Dm755 crush $out/bin/crush
  '';

  meta = {
    description = "Charmbracelet Crush, prebuilt";
    homepage = "https://github.com/charmbracelet/crush";
    license = pkgs.lib.licenses.fsl11Mit;
    mainProgram = "crush";
    platforms = [ "x86_64-linux" ];
  };
}
