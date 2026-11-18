{
  description = "NixRiot: NixOS + Panacea + OpenRiot features";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, nixos-generators, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      specialArgs = {
        inherit self inputs;
        panaceaSrc = ./panacea;
      };
    in
    {
      nixosConfigurations.nixriot = lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/example/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs // {
              nixriotUser = "user";
              nixriotApps = true;
            };
            home-manager.users.user = import ./home;
          }
        ];
      };

      nixosConfigurations.installed = lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/installed/default.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs // {
              nixriotUser = (import ./hosts/installed/local.nix).nixriotUser;
              nixriotApps = true;
            };
          }
        ];
      };

      nixosConfigurations.live = lib.nixosSystem {
        inherit system specialArgs;
        modules = [ ./iso/configuration.nix ];
      };

      packages.${system} = {
        iso = nixos-generators.nixosGenerate {
          inherit system;
          format = "iso";
          specialArgs = {
            inherit self inputs;
            panaceaSrc = ./panacea;
            installedSystem =
              self.nixosConfigurations.installed.config.system.build.toplevel;
          };
          modules = [
            ./iso/configuration.nix
            ({ lib, ... }: {
              image.baseName = lib.mkForce "NixRiot";
              isoImage.storeContents = [
                inputs.nixpkgs.outPath
                inputs.home-manager.outPath
                inputs.nixos-generators.outPath
              ];
            })
          ];
        };

        installer = import ./installer { pkgs = nixpkgs.legacyPackages.${system}; };
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
