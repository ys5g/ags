{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    astal.url = "github:aylur/astal";
  };

  outputs = {
    self,
    nixpkgs,
    astal,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    packages.${system} =
      astal.packages.${system}
      // {
        default = self.packages.${system}.ags;
        ags = pkgs.callPackage ./nix {
          astal = astal.packages.${system}.default;
        };
        agsFull = pkgs.callPackage ./nix {
          astal = astal.packages.${system}.default;
          extraPackages = builtins.attrValues (
            builtins.removeAttrs astal.packages.${system} ["docs"]
          );
        };
      };

    devShells.${system} = {
      default = astal.devShells.${system}.default.overrideAttrs (_: prev: {
        buildInputs = prev.buildInputs ++ [pkgs.go];
      });
    };

    homeManagerModules.default = import ./nix/module.nix self;
  };
}
