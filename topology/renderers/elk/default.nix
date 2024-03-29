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
    concatStringsSep
    elem
    flatten
    flip
    foldl'
    isAttrs
    last
    mapAttrs
    mapAttrsToList
    mkOption
    optional
    optionalAttrs
    optionals
    recursiveUpdate
    stringLength
    types
    ;

  mapAttrsRecursiveInner = f: set: let
    recurse = path: set:
      f path (
        flip mapAttrs set (
          name: value:
            if isAttrs value
            then recurse (path ++ [name]) value
            else value
        )
      );
  in
    recurse [] set;

  attrsToListify = ["children" "labels" "ports" "edges"];

  # Converts an attrset to a list of values with a new field id reflecting the attribute name with all parent ids appended.
  listify = path: mapAttrsToList (id: v: {id = concatStringsSep "." (path ++ [id]);} // v);

  # In nix we like to use refer to named attributes using attrsets over using lists, because it
  # has merging capabilities and allows easy referencing. But elk needs some attributes like
  # children as a list of objects, which we need to transform.
  elkifySchema = schema:
    flip mapAttrsRecursiveInner schema (
      path: value:
        if path != [] && elem (last path) attrsToListify
        then listify path value
        else value
    );

  mkEdge = from: to: extra: {
    edges."${from}__${to}" =
      {
        sources = [from];
        targets = [to];
      }
      // extra;
  };

  mkLabel = text: scale: extraStyle: {
    height = scale * 12;
    width = scale * 7.3 * (stringLength text);
    inherit text;
    style =
      {
        style = "font: ${toString (scale * 12)}px JetBrains Mono;";
      }
      // extraStyle;
  };

  netToElk = net: [
    {
      children.network.children."net:${net.id}" = {
        svg = {
          file = config.lib.renderers.svg.net.mkCard net;
          scale = 0.8;
        };
        properties."portLabels.placement" = "OUTSIDE";
      };
    }
  ];

  idForInterface = node: interfaceId: "children.node:${node.id}.ports.interface:${interfaceId}";

  nodeInterfaceToElk = node: interface:
    [
      # Interface for node in main view
      {
        children."node:${node.id}".ports."interface:${interface.id}" = {
          properties = optionalAttrs (node.preferredRenderType == "card") {
            "port.side" = "WEST";
          };
          width = 8;
          height = 8;
          style.stroke = "#70a5eb";
          style.fill = "#74bee9";
          labels =
            {
              "00-name" = mkLabel interface.id 1 {};
            }
            // optionalAttrs (interface.mac != null) {
              "50-mac" = mkLabel interface.mac 1 {fill = "#70a5eb";};
            };
        };
      }
      # Interface for node in network-centric view
      {
        children.network.children."node:${node.id}".ports."interface:${interface.id}" = {
          width = 8;
          height = 8;
          style.stroke = "#70a5eb";
          style.fill = "#74bee9";
          labels =
            {
              "00-name" = mkLabel interface.id 1 {};
            }
            // optionalAttrs (interface.mac != null) {
              "50-mac" = mkLabel interface.mac 1 {fill = "#70a5eb";};
            }
            // optionalAttrs (interface.addresses != []) {
              "60-addrs" = mkLabel (toString interface.addresses) 1 {fill = "#f9a872";};
            };
        };
      }

      # Edge in network-centric view
      (optionalAttrs (interface.network != null) (
        mkEdge ("children.network." + idForInterface node interface.id) "children.network.children.net:${interface.network}" {}
      ))
    ]
    ++ optionals (!interface.virtual) (flip map interface.physicalConnections (
      conn:
        optionalAttrs (
          (!any (y: y.node == node.id && y.interface == interface.id) config.nodes.${conn.node}.interfaces.${conn.interface}.physicalConnections)
          || (node.id < conn.node)
        ) (
          # Edge in main view
          mkEdge
          (idForInterface node interface.id)
          (idForInterface config.nodes.${conn.node} conn.interface)
          {}
        )
    ));

  nodeToElk = node:
    [
      # Add node to main view
      {
        children."node:${node.id}" = {
          svg = {
            file = config.lib.renderers.svg.node.mkPreferredRender node;
            scale = 0.8;
          };
          properties =
            {
              "portLabels.placement" = "OUTSIDE";
            }
            // optionalAttrs (node.preferredRenderType == "card") {
              "portConstraints" = "FIXED_SIDE";
            };
        };
      }
      # Add node to network-centric view
      {
        children.network.children."node:${node.id}" = {
          svg = {
            file = config.lib.renderers.svg.node.mkImageWithName node;
            scale = 0.8;
          };
          properties."portLabels.placement" = "OUTSIDE";
        };
      }
    ]
    ++ optional (node.parent != null) (
      {
        children."node:${node.parent}".ports.guests = {
          properties."port.side" = "EAST";
          width = 8;
          height = 8;
          style.stroke = "#49d18d";
          style.fill = "#78dba9";
          labels."00-name" = mkLabel "guests" 1 {};
        };
      }
      // mkEdge "children.node:${node.parent}.ports.guests" "children.node:${node.id}" {
        style.stroke-dasharray = "10,8";
        style.stroke-linecap = "round";
      }
    )
    ++ map (nodeInterfaceToElk node) (attrValues node.interfaces);
in {
  options.renderers.elk = {
    output = mkOption {
      description = "The derivation containing the rendered output";
      type = types.path;
      readOnly = true;
    };
  };

  config.renderers.elk.output = let
    graph = elkifySchema (foldl' recursiveUpdate {} (
      [
        {
          id = "root";
          layoutOptions = {
            "org.eclipse.elk.algorithm" = "layered";
            "org.eclipse.elk.edgeRouting" = "ORTHOGONAL";
            "org.eclipse.elk.direction" = "RIGHT";
            "org.eclipse.elk.layered.crossingMinimization.strategy" = true;
            "org.eclipse.elk.layered.nodePlacement.strategy" = "NETWORK_SIMPLEX";
            "org.eclipse.elk.layered.spacing.edgeNodeBetweenLayers" = 40;
            "org.eclipse.elk.layered.spacing.edgeEdgeBetweenLayers" = 25;
            "org.eclipse.elk.spacing.edgeEdge" = 50;
            "org.eclipse.elk.spacing.edgeNode" = 50;
          };
        }

        # Add network-centric section
        {
          children.network = {
            style = {
              stroke = "#101419";
              stroke-width = 2;
              fill = "#080a0d";
              rx = 12;
            };
            labels."00-name" = mkLabel "Network View" 1 {};
          };
        }

        # Add service overview
        {
          children.services-overview = {
            svg = {
              file = config.lib.renderers.svg.services.mkOverview;
              scale = 0.8;
            };
          };
        }
      ]
      ++ flatten (map netToElk (attrValues config.networks))
      ++ flatten (map nodeToElk (attrValues config.nodes))
    ));
  in
    pkgs.writeText "graph.elk.json" (builtins.toJSON graph);
}
