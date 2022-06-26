{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";
    gomod2nix.url = "github:tweag/gomod2nix";
    grpc-gateway-src = {
      flake = false;
      url = github:grpc-ecosystem/grpc-gateway;
    };
  };

  outputs =
    { self, nixpkgs, flake-utils, gomod2nix, grpc-gateway-src }:
    let
      overlays = [ gomod2nix.overlays.default ];
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system overlays; };
      in
      rec {
        packages = flake-utils.lib.flattenTree
        { 
          grpc-gateway = pkgs.buildGoApplication {
              name = "grpc-gateway";
              src = "${grpc-gateway-src}/";
              modules = ./gomod2nix.toml;
          };
        };
        
        defaultPackage = packages.grpc-gateway;
        devShell =
          pkgs.mkShell {
            buildInputs = [ pkgs.gomod2nix ];
            packages = with pkgs; [
              go_1_17
            ];
          };

        apps.grpc-gateway = flake-utils.lib.mkApp { name = "grpc-gateway"; drv = packages.grpc-gateway; };
      });
}

