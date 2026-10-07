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

        app = craneLib.buildPackage {
          pname = "pokeapi-ca-poc";
          version = "0.1.0";
          src = craneLib.cleanCargoSource ./.;
          strictDeps = true;
          nativeBuildInputs = [pkgs.pkg-config];
          buildInputs = [pkgs.openssl];
          postFixup = ''
            if [ -f "$out/bin/pokeapi-ca-poc" ]; then
              ${pkgs.removeReferencesTo}/bin/remove-references-to \
                -t ${rustToolchain} \
                "$out/bin/pokeapi-ca-poc"
            fi
          '';
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
          dockerImage = linuxPkgs.dockerTools.buildLayeredImage {
            name = "pokeapi-ca-poc";
            tag = "latest";
            contents = [linuxApp linuxPkgs.cacert];
            config = {
              Cmd = ["${linuxApp}/bin/pokeapi-ca-poc"];
              Env = ["SSL_CERT_FILE=${linuxPkgs.cacert}/etc/ssl/certs/ca-bundle.crt"];
              ExposedPorts."3000/tcp" = {};
            };
          };
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            rustToolchain
            pkgs.taplo
            pkgs.pkg-config
          ];
          buildInputs = [pkgs.openssl];

          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
      }
    );
}
