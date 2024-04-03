{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    elem
    escapeShellArg
    flip
    foldl'
    isAttrs
    last
    mapAttrs
    mapAttrsToList
    optionalAttrs
    recursiveUpdate
    stringLength
    ;
in rec {
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

  mkEdge = from: to: reverse: extra:
    if reverse
    then mkEdge to from false extra
    else {
      edges."${from}__${to}" =
        {
          sources = [from];
          targets = [to];
        }
        // extra;
    };

  mkPort = recursiveUpdate {
    width = 8;
    height = 8;
    style.stroke = "#485263";
    style.fill = "#b6beca";
  };

  mkLabel = text: scale: extraStyle: {
    height = scale * 12;
    width = scale * 7.2 * (stringLength text);
    inherit text;
    style =
      {
        style = "font: ${toString (scale * 12)}px JetBrains Mono;";
      }
      // extraStyle;
  };

  pathStyleFromNetworkStyle = style:
    {
      solid = {
        stroke = style.primaryColor;
      };
      dashed =
        {
          stroke = style.primaryColor;
          stroke-dasharray = "10,8";
          stroke-linecap = "round";
        }
        // optionalAttrs (style.secondaryColor != null) {
          background = style.secondaryColor;
        };
      dotted =
        {
          stroke = style.primaryColor;
          stroke-dasharray = "2,6";
          stroke-linecap = "round";
        }
        // optionalAttrs (style.secondaryColor != null) {
          background = style.secondaryColor;
        };
    }
    .${style.pattern};

  idForInterface = node: interfaceId: "children.node:${node.id}.ports.interface:${interfaceId}";

  interfaceLabels = interface: let
    netStyle = optionalAttrs (interface.network != null) {
      fill = config.networks.${interface.network}.style.primaryColor;
    };
  in
    {
      "00-name" = mkLabel interface.id 1 {};
    }
    // optionalAttrs (interface.mac != null) {
      "50-mac" = mkLabel interface.mac 1 netStyle;
    }
    // optionalAttrs (interface.addresses != []) {
      "60-addrs" = mkLabel (toString interface.addresses) 1 netStyle;
    };

  mkDiagram = defs:
    elkifySchema (foldl' recursiveUpdate {} (
      [
        {
          id = "root";
          layoutOptions = {
            "org.eclipse.elk.algorithm" = "layered";
            "org.eclipse.elk.edgeRouting" = "ORTHOGONAL";
            "org.eclipse.elk.direction" = "RIGHT";
            "org.eclipse.elk.layered.allowNonFlowPortsToSwitchSides" = true;
            "org.eclipse.elk.layered.crossingMinimization.strategy" = true;
            "org.eclipse.elk.layered.nodePlacement.strategy" = "NETWORK_SIMPLEX";
            "org.eclipse.elk.layered.spacing.edgeNodeBetweenLayers" = 40;
            "org.eclipse.elk.layered.spacing.edgeEdgeBetweenLayers" = 25;
            "org.eclipse.elk.spacing.edgeEdge" = 50;
            "org.eclipse.elk.spacing.edgeNode" = 50;
          };
        }
      ]
      ++ defs
    ));

  mkRender = name: diagram:
    (pkgs.runCommand "topology-diagram-${name}" {} ''
      mkdir -p $out

      echo "Rendering "${escapeShellArg name}" diagram"
      ${lib.getExe pkgs.elk-to-svg} \
        ${pkgs.writeText "${name}.elk.json" (builtins.toJSON diagram)} \
          --font ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf \
          --font-bold ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Bold.ttf \
          $out/diagram.svg
    '')
    + "/diagram.svg";
}
