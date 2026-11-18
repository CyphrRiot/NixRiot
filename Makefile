.PHONY: check build iso switch update fmt

ISO_NAME = NixRiot.iso
ISO_OUT ?= $(HOME)/Code/ISOs

check:
	nix flake check

build:
	nix build .#nixosConfigurations.nixriot.config.system.build.toplevel

iso:
	nix build .#iso
	cp -f result/iso/$(ISO_NAME) $(ISO_OUT)/$(ISO_NAME)
	chmod u+w $(ISO_OUT)/$(ISO_NAME)

switch:
	sudo nixos-rebuild switch --flake .#nixriot

update:
	nix flake update

fmt:
	nix fmt
