{
  description = "My personal NUR repository";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        # "aarch64-darwin"
      ];
      forAllSystems = function: nixpkgs.lib.genAttrs systems (system: function system);
    in
    {
      packages = forAllSystems (system: import ./default.nix {
        pkgs = import nixpkgs { inherit system; };
      });
      checks = forAllSystems (system: self.packages.${system});
    };
}
