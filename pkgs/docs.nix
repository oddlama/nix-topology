{
  lib,
  pkgs,
  runCommand,
  mdbook,
  nixosOptionsDoc,
}: let
  topologyDoc = nixosOptionsDoc {
    inherit
      (import ../. {
        inherit pkgs;
        prefix = [];
      })
      options
      ;
  };
in
  runCommand "nix-topology-documentation" {
    nativeBuildInputs = [mdbook];
  } ''
    cp -r ${../docs} docs
    chmod 755 docs docs/src
    cp ${topologyDoc.optionsCommonMark} docs/src/topology-options.md
    mkdir docs/theme
    cp ${pkgs.documentation-highlighter}/highlight.pack.js docs/theme/highlight.js
    ${lib.getExe mdbook} build -d $out docs
  ''
