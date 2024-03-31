f: {
  lib,
  config,
  options,
  ...
}: let
  inherit
    (lib)
    attrNames
    attrValues
    concatLines
    concatMap
    concatStringsSep
    const
    elem
    flatten
    flip
    foldl'
    length
    mapAttrsToList
    mkDefault
    mkIf
    mkOption
    optional
    optionalAttrs
    recursiveUpdate
    reverseList
    types
    unique
    warnIf
    ;

  inherit
    (import ../topology/lazy.nix lib)
    isLazyValue
    lazyOf
    lazyValue
    ;

  allNodes = attrNames config.nodes;
  allInterfacesOf = node: attrNames config.nodes.${node}.interfaces;
  allNodeInterfacePairs = concatMap (node: map (interface: {inherit node interface;}) (allInterfacesOf node)) allNodes;

  # Helper to add a value to a list if it doesn't already hold it
  addIfNotExists = list: x:
    if elem x list
    then list
    else list ++ [x];

  # The list of networks that were specifically assigned by the user
  # to other interfaces which are sharing their network with us.
  networkDefiningInterfaces = foldl' recursiveUpdate {} (flatten (
    flip map options.nodes.definitions (mapAttrsToList (
      nodeId: node:
        flip mapAttrsToList (node.interfaces or {}) (
          interfaceId: interface:
            optional (interface ? network && !isLazyValue interface.network) {
              ${nodeId}.${interfaceId} = interface.network;
            }
        )
    ))
  ));

  # A list of all connections between all interfaces. Bidirectional.
  connectionList = unique (flatten (flip mapAttrsToList config.nodes (
    nodeId: node:
      flip mapAttrsToList node.interfaces (
        interfaceId: interface:
          flip map interface.physicalConnections (conn: [
            {
              src = {
                node = nodeId;
                interface = interfaceId;
              };
              dst = conn;
            }
            {
              src = conn;
              dst = {
                node = nodeId;
                interface = interfaceId;
              };
            }
          ])
      )
  )));

  # A map of all connections constructed from the connection list
  connections = foldl' (acc: {
    src,
    dst,
  }:
    recursiveUpdate acc {
      ${src.node}.${src.interface} = addIfNotExists (acc.${src.node}.${src.interface} or []) dst;
    }) {}
  connectionList;

  # Propagates all networks from the source interface to the destination interface
  propagateNetworks = state: snode: sinterface: dnode: dinterface:
  #builtins.trace "  propagate all nets (${toString (attrNames state.${snode}.${sinterface})}) of ${snode}.${sinterface} to ${dnode}.${dinterface}"
  (
    # Fold over each network that the source interface shares
    # and propagate it if the destination doesn't already have this network
    foldl' (
      acc: net:
        recursiveUpdate acc (
          optionalAttrs (!(acc ? ${dnode}.${dinterface}.${net}))
          #builtins.trace "    adding ${net} to ${dnode}.${dinterface} via ${toString (acc.${snode}.${sinterface}.${net} ++ ["${snode}.${sinterface}"])}"
          {
            # Create the network on the destination interface and append our interface
            # to the list which indicates from where the network was received
            ${dnode}.${dinterface}.${net} = acc.${snode}.${sinterface}.${net} ++ ["${snode}.${sinterface}"];
          }
        )
    )
    state (attrNames state.${snode}.${sinterface})
  );

  # Propagates all shared networks for the given interface to other interfaces connected to it
  propagateToConnections = state: src:
  #builtins.trace "propagate via connections of ${src.node}.${src.interface}"
  (
    # Fold over each connection of the current interface
    foldl' (
      acc: dst:
        propagateNetworks acc src.node src.interface dst.node dst.interface
    )
    state (connections.${src.node}.${src.interface} or [])
  );

  # Propagates all shared networks for the given interface to other interfaces on the same
  # node to which the network is shared
  propagateLocally = state: src:
  #builtins.trace "propagate locally on ${src.node}.${src.interface}"
  (
    # Fold over each local interface of the current node
    foldl' (
      acc: dstInterface:
        if src.interface != dstInterface && config.nodes.${src.node}.interfaces.${src.interface}.sharesNetworkWith dstInterface
        then propagateNetworks acc src.node src.interface src.node dstInterface
        else acc
    )
    state (allInterfacesOf src.node)
  );

  # Assigns each interface a list of networks that were propagated to it
  # from another interface or connection.
  propagatedNetworks = let
    # Initially set sharedNetworks based on whether the interface has a network assigned to it.
    # This list will then be expaned iteratively.
    initial = foldl' recursiveUpdate {} (flatten (flip map allNodes (
      node:
        flip map (allInterfacesOf node) (interface: {
          ${node}.${interface} = optionalAttrs (networkDefiningInterfaces ? ${node}.${interface}) {
            ${networkDefiningInterfaces.${node}.${interface}} = [];
          };
        })
    )));

    # Takes a state and propagates networks via local sharing on the same node
    propagateEachLocally = state: foldl' propagateLocally state allNodeInterfacePairs;
    # Takes a state and propagates networks via sharing over connections
    propagateEachToConnections = state: foldl' propagateToConnections state allNodeInterfacePairs;

    # The update function that propagates state from all interfaces to all neighbors.
    # The fixpoint of this function is the solution.
    update = state: propagateEachToConnections (propagateEachLocally state);
    converged = lib.converge update initial;

    # Extract all interfaces that were assigned multiple interfaces, to issue a warning
    interfacesWithMultipleNets = flatten (
      flip mapAttrsToList converged (
        node: ifs:
          flip mapAttrsToList ifs (
            interface: nets:
              optional (length (attrNames nets) > 1) {
                inherit node interface nets;
              }
          )
      )
    );
  in
    warnIf (interfacesWithMultipleNets != []) ''
      topology: Some interfaces have received multiple networks via network propagation!
      This is an error in your network configuration that must be addressed.
      Evaluation can still continue by considering only one of them (effectively at random).
      The affected interfaces are:
      ${concatLines (flip map interfacesWithMultipleNets (
        x:
          " - ${x.node}.${x.interface}:\n"
          + concatLines (
            flip mapAttrsToList x.nets (
              net: assignments: "     ${net} assigned via ${concatStringsSep " -> " (reverseList assignments)}"
            )
          )
      ))}''
    converged;
in
  f {
    options.nodes = mkOption {
      type = types.attrsOf (types.submodule (nodeSubmod: {
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

                network =
                  mkOption {
                    description = "The id of the network to which this interface belongs, if any.";
                    type = lazyOf (types.nullOr types.str);
                  }
                  // optionalAttrs config.topology.isMainModule {
                    default = let
                      sharedNetworks = propagatedNetworks.${nodeSubmod.config.id}.${submod.config.id} or {};
                      sharedNetwork =
                        if sharedNetworks == {}
                        then null
                        else builtins.head (attrNames sharedNetworks);
                    in
                      lazyValue sharedNetwork;
                  };

                sharesNetworkWith = mkOption {
                  description = ''
                    Defines a predicate that determines whether this interface shares its connected network with another provided local interface.
                    The predicates takes the name of another interface and returns true if our network should be shared with the given interface.

                    Sharing here means that if a network is set on this interface, it will also be set as the network for any
                    shared interface. Setting the same predicate on multiple interfaces causes them to share a network regardless
                    on which port the network is actually defined.

                    An unmanaged switch for example would set this to `const true`, effectively
                    propagating the network set on one port to all other ports. Having two assigned
                    networks within one predicate group will cause a warning to be issued.
                  '';
                  default = const false;
                  defaultText = ''const false'';
                  type = types.functionTo types.bool;
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

                      renderer.reverse = mkOption {
                        description = "Whether to reverse the edge. Can be useful to affect node positioning if the layouter is directional.";
                        type = types.bool;
                        default = false;
                      };
                    };
                  });
                };

                # Rendering related hints and settings
                renderer = {
                  hidePhysicalConnections = mkOption {
                    description = ''
                      Whether to hide physical connections of this interface in renderings.
                      Affects both outgoing connections defined here and incoming connections
                      defined on other interfaces.

                      Usually only affects rendering of the main topology view, not network-centric views.
                    '';
                    type = types.bool;
                    default = false;
                  };
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
      }));
    };

    config = {
      lib.a.a = connections;
      lib.a.b = networkDefiningInterfaces;
      lib.a.c = propagatedNetworks;
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
