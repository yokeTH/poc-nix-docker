# Axum + Nix Docker PoC

dependency-layer reuse poc

## Result

cache Github action cache hit + layer reuse

## Run locally

```sh
nix develop -c cargo run
```

```sh
curl http://localhost:3000/health
curl http://localhost:3000/pokemon/pikachu
```

## Build the image

```sh
nix build .#dockerImage
docker load < result
docker run --rm -p 3000:3000 pokeapi-ca-poc:latest
```
