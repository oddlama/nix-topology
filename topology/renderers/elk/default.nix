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
    optionals
    optionalAttrs
    recursiveUpdate
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

  netToElk = net: {
    children."net:${net.id}" = {
      width = 50;
      height = 50;
    };
  };

  idForInterface = node: interfaceId:
    if (node.preferredRenderType == "card")
    then "children.node:${node.id}.ports.interface:${interfaceId}"
    else "children.node:${node.id}";

  nodeInterfaceToElk = node: interface:
    [
      (optionalAttrs (node.preferredRenderType == "card") {
        children."node:${node.id}".ports."interface:${interface.id}" = {
          properties."port.side" = "WEST";
          #x = 0;
          #y = 82 + 42 * lib.lists.findFirstIndex (x: x == interface.id) 0 (builtins.attrNames node.interfaces); # FIXME: just pass index along in function call
          width = 8;
          height = 8;
          # TODO: FIXME: not shown currently in svg
          # labels.name = {
          #   text = interface.id;
          #   width = 33.0;
          #   height = 15.0;
          # };
        };
      })
    ]
    ++ optionals (!interface.virtual) (flip map interface.physicalConnections (x:
      optionalAttrs (
        (!any (y: y.node == node.id && y.interface == interface.id) config.nodes.${x.node}.interfaces.${x.interface}.physicalConnections)
        || (node.id < x.node)
      ) {
        edges."node:${node.id}.ports.interface:${interface.id}-to-node:${x.node}.ports.interface:${x.interface}" = {
          sources = [(idForInterface node interface.id)];
          targets = [(idForInterface config.nodes.${x.node} x.interface)];
        };
      }));

  nodeToElk = node:
    [
      {
        children."node:${node.id}" = {
          svg = {
            file = config.lib.renderers.svg.node.mkPreferredRender node;
            scale = 0.8;
          };
          properties."portConstraints" = "FIXED_SIDE";
        };
      }
    ]
    ++ optional (node.parent != null) {
      children."node:${node.parent}".ports.guests = {
        properties."port.side" = "EAST";
        width = 8;
        height = 8;
      };
      edges."node:${node.parent}.ports.guests-to-node:${node.id}" = {
        sources = ["children.node:${node.parent}.ports.guests"];
        targets = ["children.node:${node.id}"];
        style.stroke-dasharray = "10,8";
        style.stroke-linecap = "round";
      };
    }
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
