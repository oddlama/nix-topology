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
    optionalString
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
    ${net.id}: ${net.name} {
      info: |md
      ${net.cidrv4}
      ${net.cidrv6}
      |
    }
  '';

  nodeInterfaceToD2 = node: interface:
    ''
      ${node.id}.${interface.id}: ${interface.id} {
        info: |md
        ${toString interface.mac}
        ${toString interface.addresses}
        ${toString interface.gateways}
        |
      }
    ''
    + optionalString (interface.network != null) ''
      ${node.id}.${interface.id} -- ${interface.network}
    '';
  # TODO: deduplicate first
  #+ concatLines (flip map interface.physicalConnections (x: ''
  #  ${node.id}.${interface.id} -- ${x.node}.${x.interface}
  #''));

  nodeToD2 = node: ''
    ${node.id}: ${node.name} {}

    ${concatLines (map (nodeInterfaceToD2 node) (attrValues node.interfaces))}
  '';
in
  pkgs.writeText "network.d2" ''
    ${concatLines (map netToD2 (attrValues config.networks))}
    ${concatLines (map nodeToD2 (attrValues config.nodes))}
  ''
