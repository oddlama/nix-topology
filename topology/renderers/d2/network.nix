{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit
    (lib)
    any
    attrValues
    concatLines
    flip
    optionalString
    ;

  netToD2 = net: ''
    net_${net.id}: ${net.name} {
      info: |md
      ${net.cidrv4}
      ${net.cidrv6}
      |
    }
  '';

  nodeInterfaceToD2 = node: interface:
    concatLines (flip map interface.physicalConnections (x:
      optionalString (
        (!any (y: y.node == node.id && y.interface == interface.id) config.nodes.${x.node}.interfaces.${x.interface}.physicalConnections)
        || (node.id < x.node)
      )
      ''
        node_${node.id} -- node_${x.node}: "" {
          source-arrowhead.label: ${interface.id}
          target-arrowhead.label: ${x.interface}
        }
      ''));

  nodeToD2 = node: ''
    node_${node.id}: "" {
      shape: image
      width: 680
      icon: ${config.lib.renderers.svg.node.mkPreferredRender node}
    }

    ${concatLines (map (nodeInterfaceToD2 node) (attrValues node.interfaces))}
  '';
in
  pkgs.writeText "network.d2" ''
    ${concatLines (map netToD2 (attrValues config.networks))}
    ${concatLines (map nodeToD2 (attrValues config.nodes))}
  ''
