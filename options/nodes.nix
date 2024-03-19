f: {
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    attrValues
    flatten
    flip
    literalExpression
    mkDefault
    mkIf
    mkOption
    types
    ;
in
  f {
    options.nodes = mkOption {
      default = {};
      description = ''
        Defines nodes that are shown in the topology graph.
        Nodes usually correspond to nixos hosts or other devices in your network.
      '';
      type = types.attrsOf (types.submodule (nodeSubmod: {
        options = {
          id = mkOption {
            description = "The id of this node";
            default = nodeSubmod.config._module.args.name;
            readOnly = true;
            type = types.str;
          };

          name = mkOption {
            description = "The name of this node";
            type = types.str;
            default = nodeSubmod.config.id;
            defaultText = literalExpression ''"<name>"'';
          };

          icon = mkOption {
            description = "The icon representing this node. Usually shown next to the name. Must be a path to an image or a valid icon name (<category>.<name>).";
            type = types.nullOr (types.either types.path types.str);
            default = null;
          };

          # FIXME: TODO emoji / icon
          # FIXME: TODO hardware description "Odroid H3"
          # FIXME: TODO hardware image

          deviceType = mkOption {
            description = "TODO";
            type = types.enum ["nixos" "microvm" "nixos-container"];
          };

          deviceIcon = mkOption {
            description = "The icon representing this node's type. Must be a path to an image or a valid icon name (<category>.<name>). By default an icon will be selected based on the deviceType.";
            type = types.nullOr (types.either types.path types.str);
            default = null;
          };

          parent = mkOption {
            description = "The id of the parent node, if this node has a parent.";
            default = null;
            type = types.nullOr types.str;
          };
        };

        config = {
          # Set the default icon, if an icon exists with a matching name
          deviceIcon = mkIf (config.topology.isMainModule && config.icons.devices ? ${nodeSubmod.config.deviceType}) (
            mkDefault ("devices." + nodeSubmod.config.deviceType)
          );
        };
      }));
    };

    config = {
      assertions = flatten (
        flip map (attrValues config.nodes) (
          node: [
            (config.lib.assertions.iconValid
              node.icon "nodes.${node.id}.icon")
            (config.lib.assertions.iconValid
              node.deviceIcon "nodes.${node.id}.deviceIcon")
          ]
        )
      );
    };
  }
