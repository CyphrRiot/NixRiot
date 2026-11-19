.PHONY: check build iso switch update fmt

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
