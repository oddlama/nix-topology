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
    mkDefault
    mkIf
    mkOption
    optional
    types
    ;
in
  f {
    options.nodes = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          interfaces = mkOption {
            description = "TODO";
            default = {};
            type = types.attrsOf (types.submodule (submod: {
              options = {
                id = mkOption {
                  description = "The id of this interface";
                  type = types.str;
                  readOnly = true;
                  default = submod.config._module.args.name;
                };

                virtual = mkOption {
                  description = "Whether this is a virtual interface.";
                  type = types.bool;
                  default = false;
                };

                mac = mkOption {
                  description = "The MAC address of this interface, if known.";
                  default = null;
                  type = types.nullOr types.str;
                };

                type = mkOption {
                  description = "The type of this interface";
                  default = "ethernet";
                  type = types.str;
                };

                icon = mkOption {
                  description = "The icon representing this interface's type. Must be a path to an image or a valid icon name (<category>.<name>). By default an icon will be selected based on the type.";
                  type = types.nullOr (types.either types.path types.str);
                  default = null;
                };

                addresses = mkOption {
                  description = "The configured address(es), or a descriptive string (like DHCP).";
                  default = [];
                  type = types.listOf types.str;
                };

                gateways = mkOption {
                  description = "The configured gateways, if any.";
                  default = [];
                  type = types.listOf types.str;
                };

                network = mkOption {
                  description = "The id of the network to which this interface belongs, if any.";
                  default = null;
                  type = types.nullOr types.str;
                };

                physicalConnections = mkOption {
                  description = "A list of other node interfaces to which this node is physically connected.";
                  default = [];
                  type = types.listOf (types.submodule {
                    options = {
                      node = mkOption {
                        description = "The other node id.";
                        type = types.str;
                      };

                      interface = mkOption {
                        description = "The other node's interface id.";
                        type = types.str;
                      };
                    };
                  });
                };
              };

              config = {
                # Set the default icon, if an icon exists with a matching name
                icon = mkIf (config.topology.isMainModule && config.icons.interfaces ? ${submod.config.type}) (
                  mkDefault ("interfaces." + submod.config.type)
                );
              };
            }));
          };
        };
      });
    };

    config = {
      assertions = flatten (flip map (attrValues config.nodes) (
        node:
          flip map (attrValues node.interfaces) (
            interface:
              [
                {
                  assertion = interface.network != null -> config.networks ? ${interface.network};
                  message = "topology: nodes.${node.id}.interfaces.${interface.id} refers to an unknown network '${interface.network}'";
                }
                (config.lib.assertions.iconValid
                  interface.icon "nodes.${node.id}.interfaces.${interface.id}")
              ]
              ++ flip map interface.physicalConnections (
                physicalConnection: {
                  assertion = config.nodes ? ${physicalConnection.node} && config.nodes.${physicalConnection.node}.interfaces ? ${physicalConnection.interface};
                  message = "topology: nodes.${node.id}.interfaces.${interface.id}.physicalConnections refers to an unknown node/interface nodes.${physicalConnection.node}.interfaces.${physicalConnection.interface}";
                }
              )
          )
      ));

      warnings = flatten (flip map (attrValues config.nodes) (
        node:
          flip map (attrValues node.interfaces) (
            interface:
              flip map interface.physicalConnections (
                physicalConnection: let
                  otherNetwork = config.nodes.${physicalConnection.node}.interfaces.${physicalConnection.interface}.network or null;
                in
                  optional (interface.network != null && otherNetwork != null && interface.network != otherNetwork)
                  "topology: The interface nodes.${node.id}.interfaces.${interface.id} is associated with the network (${interface.network}), but also has a physicalConnection to nodes.${physicalConnection.node}.interfaces.${physicalConnection.interface} which is associated to a different network (${otherNetwork})"
              )
          )
      ));
    };
  }
