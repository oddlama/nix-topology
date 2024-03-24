{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    any
    attrValues
    concatLines
    flip
    mkOption
    optionalString
    types
    ;

  toBase64 = text: let
    inherit (lib) sublist mod stringToCharacters concatMapStrings;
    inherit (lib.strings) charToInt;
    inherit (builtins) substring foldl' genList elemAt length concatStringsSep stringLength;
    lookup = stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789__";
    sliceN = size: list: n: sublist (n * size) size list;
    pows = [(64 * 64 * 64) (64 * 64) 64 1];
    intSextets = i: map (j: mod (i / j) 64) pows;
    compose = f: g: x: f (g x);
    intToChar = elemAt lookup;
    convertTripletInt = sliceInt: concatMapStrings intToChar (intSextets sliceInt);
    sliceToInt = foldl' (acc: val: acc * 256 + val) 0;
    convertTriplet = compose convertTripletInt sliceToInt;
    join = concatStringsSep "";
    convertLastSlice = slice: let
      len = length slice;
    in
      if len == 1
      then (substring 0 2 (convertTripletInt ((sliceToInt slice) * 256 * 256))) + "__"
      else if len == 2
      then (substring 0 3 (convertTripletInt ((sliceToInt slice) * 256))) + "_"
      else "";
    len = stringLength text;
    nFullSlices = len / 3;
    bytes = map charToInt (stringToCharacters text);
    tripletAt = sliceN 3 bytes;
    head = genList (compose convertTriplet tripletAt) nFullSlices;
    tail = convertLastSlice (tripletAt nFullSlices);
  in
    join (head ++ [tail]);

  netToElk = net: ''
    node net_${toBase64 net.id} {
      label "${net.name}"
    }
  '';

  nodeInterfaceToElk = node: interface:
    concatLines (flip map interface.physicalConnections (x:
      optionalString (
        (!any (y: y.node == node.id && y.interface == interface.id) config.nodes.${x.node}.interfaces.${x.interface}.physicalConnections)
        || (node.id < x.node)
      )
      ''
        edge node_${toBase64 node.id} -> node_${toBase64 x.node}
      ''));

  nodeToElk = node: ''
    node node_${toBase64 node.id} {
      layout [size: 680, 0]
      label "${node.name}"
    }

    ${concatLines (map (nodeInterfaceToElk node) (attrValues node.interfaces))}
  '';
in {
  options.renderers.elk = {
    output = mkOption {
      description = "The derivation containing the rendered output";
      type = types.path;
      readOnly = true;
    };
  };

  config.renderers.elk.output = pkgs.writeText "graph.elk" ''
    interactiveLayout: true
    separateConnectedComponents: false
    crossingMinimization.semiInteractive: true
    elk.direction: RIGHT

    ${concatLines (map netToElk (attrValues config.networks))}
    ${concatLines (map nodeToElk (attrValues config.nodes))}
  '';
}
