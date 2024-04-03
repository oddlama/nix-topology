{
  lib,
  pkgs,
  runCommand,
  mdbook,
  nixosOptionsDoc,
  flakeInputs,
  flakeOutputs,
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

  flakeForExample = path: let
    self = (import (path + "/flake.nix")).outputs {
      inherit (flakeInputs) nixpkgs flake-utils;
      inherit self;
      nix-topology = flakeOutputs // {outPath = ./..;};
    };
  in
    self;

  addDocForExample = exampleName: exampleOut:
  /*
  bash
  */
  ''
    EXAMPLE_DIR=docs/src/examples/${exampleName}
    mkdir -p "$EXAMPLE_DIR"
    cp ${exampleOut}/* "$EXAMPLE_DIR"/
    cat > "$EXAMPLE_DIR"/main.md <<EOF
    # Example: ${exampleName}

    #### Main view (click to enlarge)
    [![](./main.svg)](./main.svg)

    #### Network view (click to enlarge)
    [![](./network.svg)](./network.svg)

    #### flake.nix

    \`\`\`nix
    EOF

    cat ${../examples/${exampleName}/flake.nix} >> "$EXAMPLE_DIR"/main.md

    cat >> "$EXAMPLE_DIR"/main.md <<EOF
    \`\`\`
    EOF
    echo '- [${exampleName}](./examples/${exampleName}/main.md)' >> docs/src/SUMMARY.md
  '';

  examples =
    lib.mapAttrs (
      dir: _:
        (flakeForExample ../examples/${dir}).topology.${pkgs.hostPlatform.system}.config.output
    )
    (lib.filterAttrs (_: v: v == "directory") (builtins.readDir ../examples));
in
  runCommand "nix-topology-documentation" {
    nativeBuildInputs = [mdbook];
  } ''
    cp -r ${../docs} docs
    chmod 755 docs docs/src
    chmod 644 docs/src/SUMMARY.md
    mkdir docs/theme
    ${lib.concatLines (lib.mapAttrsToList addDocForExample examples)}
    cp ${topologyDoc.optionsCommonMark} docs/src/topology-options.md
    cp ${pkgs.documentation-highlighter}/highlight.pack.js docs/theme/highlight.js
    ${lib.getExe mdbook} build -d $out docs
  ''
