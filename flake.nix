{
  inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
 # inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
 
  outputs = { determinate, nixpkgs, chaotic, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Load the Determinate module
        determinate.nixosModules.default
        ./configuration.nix
        chaotic.nixosModules.default
      ];
    };
  };
}
