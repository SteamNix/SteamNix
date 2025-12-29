{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  
  inputs.jovian = {
    url = "github:Jovian-Experiments/Jovian-NixOS";
    inputs.nixpkgs.follows = "nixpkgs";
  };
 
  outputs = { nixpkgs, jovian, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        jovian.nixosModules.default
      ];
    };
  };
}
