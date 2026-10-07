{
  pkgs,
  craneLib,
  rustToolchain,
}:
craneLib.buildPackage {
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
}
