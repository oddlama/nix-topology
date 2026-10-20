{ lib }:
let
  serviceFiles = lib.filterAttrs (
    n: t: t == "regular" && lib.hasSuffix ".nix" n && n != "default.nix"
  ) (builtins.readDir ./.);

  # mkDefault per field (and per nixos.* field), so overriding one keeps the others
  asDefaults = lib.mapAttrs (
    n: v: if n == "nixos" then lib.mapAttrs (_: lib.mkDefault) v else lib.mkDefault v
  );
in
lib.mapAttrs' (filename: _: {
  name = lib.removeSuffix ".nix" filename;
  value = asDefaults (builtins.removeAttrs (import ./${filename} { inherit lib; }) [ "test" ]);
}) serviceFiles
