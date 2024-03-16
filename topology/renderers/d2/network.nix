{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit
    (lib)
    attrValues
    concatLines
    ;

  #toD2 = _nodeName: node: ''
  #  ${node.id}: |md
  #  # ${node.id}

  #  ## Disks:
  #  ${concatLines (mapAttrsToList (_: v: "- ${v.id}") node.disks)}

  #  ## Interfaces:
  #  ${concatLines (mapAttrsToList (_: v: "- ${v.id}, mac ${toString v.mac}, addrs ${toString v.addresses}, network ${toString v.network}") node.interfaces)}

  #  ## Firewall Zones:
  #  ${concatLines (mapAttrsToList (_: v: "- ${v.id}, mac ${toString v.mac}, addrs ${toString v.addresses}, network ${toString v.network}") node.firewallRules)}

  #  ## Services:
  #  ${concatLines (mapAttrsToList (_: v: "- ${v.id}, name ${toString v.name}, icon ${toString v.icon}, url ${toString v.url}") node.services)}
  #  |
  #'';

  netToD2 = net: ''
    ${net.id}: |md
    # ${net.name}
    ${net.cidrv4}
    ${net.cidrv6}
    |
  '';

  nodeInterfaceToD2 = node: interface: ''
    ${node.id}.${interface.id}: |md
    ## ${interface.id}
    |

    ${node.id}.${interface.id} -> ${interface.network}
  '';

  nodeToD2 = node: ''
    ${node.id}: |md
    # ${node.name}
    |

    ${concatLines (map (nodeInterfaceToD2 node) (attrValues node.interfaces))}
  '';
in
  pkgs.writeText "network.d2" ''
    ${concatLines (map netToD2 (attrValues config.networks))}
    ${concatLines (map nodeToD2 (attrValues config.nodes))}
  ''
