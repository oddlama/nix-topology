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
    mkOption
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
                  assertion = config.networks ? ${interface.network};
                  message = "topology: nodes.${node.id}.interfaces.${interface.id} refers to an unknown network '${interface.network}'";
                }
              ]
              ++ flip map interface.physicalConnections (
                physicalConnection: {
                  assertion = config.nodes ? ${physicalConnection.node} && config.nodes.${physicalConnection.node}.interfaces ? ${physicalConnection.interface};
                  message = "topology: nodes.${node.id}.interfaces.${interface.id}.physicalConnections refers to an unknown node/interface nodes.${physicalConnection.node}.interfaces.${physicalConnection.interface}";
                }
              )
          )
      ));
    };
  }
