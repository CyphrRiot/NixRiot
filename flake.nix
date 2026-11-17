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
        inherit inputs;
        panaceaSrc = ./vendor/panacea;
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
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.riot = import ./home;
          }
        ];
      };

      packages.${system}.iso = nixos-generators.nixosGenerate {
        inherit system;
        format = "iso";
        modules = [ ./iso/configuration.nix ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
