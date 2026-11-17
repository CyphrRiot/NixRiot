PANACEA_REPO = https://github.com/EnsixD/Panacea
PANACEA_REV = 45ddf2e11d5193779d4539ebde3ee3376c87870a

.PHONY: check build iso switch update fmt vendor-panacea vendor-diff

check:
	nix flake check

build:
	nix build .#nixosConfigurations.nixriot.config.system.build.toplevel

iso:
	nix build .#iso

switch:
	sudo nixos-rebuild switch --flake .#nixriot

update:
	nix flake update

fmt:
	nix fmt

vendor-panacea:
	rm -rf .vendor-panacea
	git clone --filter=blob:none --sparse $(PANACEA_REPO) .vendor-panacea
	cd .vendor-panacea && git sparse-checkout set panacea hypr foot fish fastfetch nano applications bin grub sddm assets && git checkout $(PANACEA_REV)
	@echo "Upstream checkout in .vendor-panacea. Diff against vendor/panacea, then copy deliberately."

vendor-diff:
	diff -ru --exclude=wallpaper --exclude=LOCAL-CHANGES.md vendor/panacea .vendor-panacea || true
