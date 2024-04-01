{
  config,
  lib,
  ...
} @ args: let
  inherit
    (lib)
    attrValues
    flatten
    optionalAttrs
    ;

  inherit
    (import ./lib.nix args)
    idForInterface
    interfaceLabels
    mkDiagram
    mkEdge
    mkLabel
    mkPort
    mkRender
    pathStyleFromNetworkStyle
    ;

  netToElk = net: [
    {
      children."net:${net.id}" = {
        svg = {
          file = config.lib.renderers.svg.net.mkCard net;
          scale = 0.8;
        };
        properties."portLabels.placement" = "OUTSIDE";

        ports.default = mkPort {
          labels."00-name" = mkLabel "*" 1 {};
        };
      };
    }
  ];

  nodeInterfaceToElk = node: interface: [
    # Interface for node in network-centric view
    {
      children."node:${node.id}".ports."interface:${interface.id}" = mkPort {
        labels = interfaceLabels interface;
      };
    }

    # Edge in network-centric view
    (optionalAttrs (interface.network != null) (
      mkEdge (idForInterface node interface.id) "children.net:${interface.network}.ports.default" interface.virtual {
        style = pathStyleFromNetworkStyle config.networks.${interface.network}.style;
      }
    ))
  ];

  nodeToElk = node:
    [
      # Add node to network-centric view
      {
        children."node:${node.id}" = {
          svg = {
            file = config.lib.renderers.svg.node.mkImageWithName node;
            scale = 0.8;
          };
          properties."portLabels.placement" = "OUTSIDE";
        };
      }
    ]
    ++ map (nodeInterfaceToElk node) (attrValues node.interfaces);
in rec {
  diagram = mkDiagram (
    flatten (map netToElk (attrValues config.networks))
    ++ flatten (map nodeToElk (attrValues config.nodes))
  );
  render = mkRender "network" diagram;
}
