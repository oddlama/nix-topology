{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit
    (lib)
    concatLines
    mapAttrsToList
    ;

  toD2 = _nodeName: node: ''
    ${node.name}: |md
    # ${node.name}

    ## Disks:
    ${concatLines (mapAttrsToList (_: v: "- ${v.name}") node.disks)}

    ## Interfaces:
    ${concatLines (mapAttrsToList (_: v: "- ${v.name}, mac ${toString v.mac}, addrs ${toString v.addresses}, network ${toString v.network}") node.interfaces)}

    ## Firewall Zones:
    ${concatLines (mapAttrsToList (_: v: "- ${v.name}, mac ${toString v.mac}, addrs ${toString v.addresses}, network ${toString v.network}") node.firewallRules)}
    |
  '';
in
  pkgs.writeText "network.d2" ''
    ${concatLines (mapAttrsToList toD2 config.nodes)}
  ''
