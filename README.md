# Ezlo

<img src="./ezlo.svg" align="left" height="200px">

Ezlo is a utility designed to validate and lint Nix derivation from nixpkgs.

```shell
nix run github:Sigmanificient/ezlo -- \
 --attr=python3Packages.qtile ~/repos/nixpkgs
```
