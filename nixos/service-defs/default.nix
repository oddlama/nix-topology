{ lib }:
let
  serviceFiles = lib.filterAttrs (
    n: t: t == "regular" && lib.hasSuffix ".nix" n && n != "default.nix"
  ) (builtins.readDir ./.);

  # mkDefault per field (and per nixos.*/oci.* field), so overriding one keeps the others.
  # oci.repos stays a normal definition, so a user's repos are added to the built-in ones.
  asDefaults = lib.mapAttrs (
    n: v:
    if n == "nixos" then
      lib.mapAttrs (_: lib.mkDefault) v
    else if n == "oci" then
      lib.mapAttrs (k: if k == "repos" then lib.id else lib.mkDefault) v
    else
      lib.mkDefault v
  );
in
lib.mapAttrs' (filename: _: {
  name = lib.removeSuffix ".nix" filename;
  value = asDefaults (builtins.removeAttrs (import ./${filename} { inherit lib; }) [ "test" ]);
}) serviceFiles
