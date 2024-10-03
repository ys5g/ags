{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    astal.url = "github:aylur/astal";

    # systems.url = "github:nix-systems/default-linux";
  };

  outputs = {
    self,
    nixpkgs,
    astal,
    # systems,
  }: let
    # The way I prefer it:
    #   forAllSystems = fn: nixpkgs.lib.genAttrs (import systems) (sys: fn {
    #     inherit sys;
    #     pkgs = nixpkgs.legacyPackages.${sys};
    #   });
    # in
    #   packages = forAllSystems ({pkgs, sys}:
    # <insert identical code, except for extra references to ${sys}>...
    #  devShells = forAllSystems ({pkgs, sys}:
    # <insert identical code>...
    # AGSv1 style:
    # Actual cross-system support is disabled since astal doesn't support it
    genSystems =
      nixpkgs.lib.genAttrs ["x86_64-linux"]
      /*
      (import systems)
      */
      ;
    pkgs = genSystems (sys: nixpkgs.legacyPackages.${sys});
  in {
    packages = genSystems (sys:
      astal.packages.${sys}
      // {
        default = self.packages.${sys}.ags;
        ags = pkgs.${sys}.callPackage ./nix {
          astal = astal.packages.${sys}.default;
        };
        agsFull = pkgs.${sys}.callPackage ./nix {
          astal = astal.packages.${sys}.default;
          extraPackages = builtins.attrValues (
            builtins.removeAttrs astal.packages.${sys} ["docs"]
          );
        };
      });

    lib = genSystems (sys: {
      bundle = import ./nix/bundle.nix self pkgs.${sys};
    });

    devShells = genSystems (sys: {
      default = astal.devShells.${sys}.default.overrideAttrs (_: prev: {
        buildInputs = prev.buildInputs ++ [pkgs.${sys}.go];
      });
    });

    homeManagerModules.default = import ./nix/module.nix self;
  };
}
