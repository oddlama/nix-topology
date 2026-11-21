{ pkgs, ... }:
let
  inherit (pkgs) lib;
  ociLib = import ../nixos/oci-lib.nix { inherit lib; };
  serviceDefs = import ../nixos/service-defs { inherit lib; };
  entries = lib.filterAttrs (_: repos: repos != [ ]) (
    lib.mapAttrs (_: def: def.oci.repos or [ ]) serviceDefs
  );
  corpus = import ./oci-image-corpus.nix;

  failures = lib.concatLists (
    lib.mapAttrsToList (
      image: want:
      let
        got = ociLib.bestMatches entries (ociLib.parseImage image);
      in
      lib.optional (
        got != lib.optional (want != null) want
      ) "${image}: expected ${builtins.toJSON want}, got ${builtins.toJSON got}"
    ) corpus
  );
  matched = lib.length (lib.filter (x: x != null) (lib.attrValues corpus));
in
if failures != [ ] then
  throw "OCI image corpus test failed:\n${lib.concatStringsSep "\n" failures}"
else
  pkgs.runCommandLocal "oci-image-corpus-test" { } ''
    echo "OCI image corpus test passed: ${toString (lib.length (lib.attrNames corpus))} images, ${toString matched} matched"
    echo "ok" > $out
  ''
