{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    flake-utils,
    crane,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = (pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml).override {
          extensions = ["rust-src"];
        };
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        app = pkgs.callPackage ./package.nix {
          inherit craneLib rustToolchain;
        };

        linuxSystem = if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64-linux" else "x86_64-linux";
        linuxPkgs = import nixpkgs {
          system = linuxSystem;
          inherit overlays;
        };
        linuxApp = self.packages.${linuxSystem}.default;
      in {
        packages = {
          default = app;
          dockerImage = linuxPkgs.callPackage ./image.nix {
            app = linuxApp;
          };
        };

        devShells.default = pkgs.callPackage ./shell.nix {
          inherit rustToolchain;
        };
      }
    );
}
