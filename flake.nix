{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system:
        function {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
        });
  in {
    devShells = forAllSystems ({
      pkgs,
      system,
    }: {
      default = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.ezlo];

        packages = with pkgs; [
          ruff
        ];
      };
    });

    packages = forAllSystems ({
      pkgs,
      system,
    }: {
      ezlo = pkgs.callPackage ./. { };
    });
  };
}

