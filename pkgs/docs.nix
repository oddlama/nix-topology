{
  lib,
  pkgs,
  runCommand,
  mdbook,
  nixosOptionsDoc,
}: let
  topologyDoc = nixosOptionsDoc {
    inherit
      (import ../. {inherit pkgs;})
      options
      ;
  };
in
  runCommand "nix-topology-documentation" {
    nativeBuildInputs = [mdbook];
  } ''
    cp -r ${../docs} docs
    chmod u+w docs/src
    cp ${topologyDoc.optionsCommonMark} docs/src/topology-options.md
    ${lib.getExe mdbook} build -d $out docs
  ''
