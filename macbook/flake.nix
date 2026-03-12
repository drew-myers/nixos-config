{
  description = "Drew's MacBook Pro — nix-darwin + home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colima = {
      url = "github:abiosoft/colima";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, colima, ... }: {
    darwinConfigurations."Drews-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.acmyers = import ./home.nix;
          home-manager.extraSpecialArgs = {
            inherit colima;
          };
        }
      ];
    };
  };
}
