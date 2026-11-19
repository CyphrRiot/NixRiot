{
  description = "NixRiot: NixOS + Panacea + OpenRiot features";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { self, nixpkgs, home-manager, ... }@inputs:
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
        iso = self.nixosConfigurations.live.config.system.build.images.iso;

        installer = import ./installer { pkgs = nixpkgs.legacyPackages.${system}; };
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
