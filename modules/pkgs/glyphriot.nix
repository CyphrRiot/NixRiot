{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "glyphriot";
  version = "unstable-2026-11-17";

  src = fetchFromGitHub {
    owner = "CyphrRiot";
    repo = "glyphriot";
    rev = "4105c91dace1bf1b3960e89d94e1e98ca4553013";
    hash = "sha256-VDtH/s3beH8b/Peb1xyugwdUpEGFEaR3lxR9tJh0IT0=";
  };

  vendorHash = "sha256-YuAzuvITKeyDHR2ahyJgrpgepUPsBWrB3Sc2oQTVtf0=";

  ldflags = [ "-X main.version=${version}" ];

  meta = {
    description = "Seed-phrase glyph obfuscation for self-custody wallets";
    homepage = "https://github.com/CyphrRiot/glyphriot";
    license = lib.licenses.mit;
    mainProgram = "glyphriot";
  };
}
