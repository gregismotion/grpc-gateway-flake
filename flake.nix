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
        
        setup = pkgs.writeScriptBin "setup" ''
          export GOPATH=$(pwd)/gopath
          export SRC_PATH=$GOPATH/src/github.com/grpc-ecosystem/grpc-gateway
          mkdir -p $SRC_PATH
          pushd $SRC_PATH
          cp -r ${grpc-gateway-src}/* .
          popd
        '';
      in
      rec {
        packages = flake-utils.lib.flattenTree
        { 
          protoc-gen-grpc-gateway = pkgs.buildGoApplication {
              name = "protoc-gen-grpc-gateway";
              src = "${grpc-gateway-src}/protoc-gen-grpc-gateway/";
              modules = ./gomod2nix.toml;
          };
          protoc-gen-openapiv2 = pkgs.buildGoApplication {
              name = "protoc-gen-openapiv2";
              src = "${grpc-gateway-src}/protoc-gen-openapiv2/";
              modules = ./gomod2nix.toml;
          };
        };

        devShell =
          pkgs.mkShell {
            buildInputs = [ pkgs.gomod2nix setup ];
            packages = with pkgs; [
              go_1_17
            ];
          };

        apps.protoc-gen-grpc-gateway = flake-utils.lib.mkApp { name = "protoc-gen-grpc-gateway"; drv = packages.protoc-gen-grpc-gateway; };
        apps.protoc-gen-openapiv2 = flake-utils.lib.mkApp { name = "protoc-gen-openapiv2"; drv = packages.protoc-gen-openapiv2; };
      });
}

