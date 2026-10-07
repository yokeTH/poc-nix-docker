{
  pkgs,
  rustToolchain,
}:
pkgs.mkShell {
  nativeBuildInputs = [
    rustToolchain
    pkgs.taplo
    pkgs.pkg-config
  ];
  buildInputs = [pkgs.openssl];

  RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
}
