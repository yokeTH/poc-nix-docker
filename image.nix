{
  dockerTools,
  cacert,
  app,
}:
dockerTools.buildLayeredImage {
  name = "pokeapi-ca-poc";
  tag = "latest";
  contents = [app cacert];
  config = {
    Cmd = ["${app}/bin/pokeapi-ca-poc"];
    Env = ["SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"];
    ExposedPorts."3000/tcp" = {};
  };
}
