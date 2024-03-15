{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    attrNames
    flip
    mkAliasOptionModule
    mkOption
    types
    ;
in {
  imports =
    [
      # Allow simple alias to set/get attributes of this node
      (mkAliasOptionModule ["topology" "self"] ["topology" "nodes" config.topology.id])
    ]
    ++ flip map (attrNames (builtins.readDir ../options)) (x:
      import ../options/${x} (
        module:
          module
          // {
            # Move options to subpath
            options.topology = module.options or {};
            # Set the correct filename for diagnostics
            _file = ../options/${x};
            # The config should only be applied on the toplevel topology module,
            # not for each nixos node.
            config = {};
          }
      ));

  options.topology = {
    id = mkOption {
      description = ''
        The attribute name in the given `nodes` which corresponds to this host.
        Please overwrite it with a unique identifier if your hostnames are not
        unique or don't reflect the name you use to refer to that node.
      '';
      default = config.networking.hostName;
      type = types.str;
    };
  };

  config.topology = {
    # Ensure a node exists for this host
    nodes.${config.topology.id} = {};
  };

  #config.topology = mkMerge [
  #  {
  #    ################### TODO user config! #################
  #    id = config.node.name;
  #    ################### END user config   #################

  #    guests =
  #      flip mapAttrsToList (config.microvm.vms or {})
  #      (_: vmCfg: vmCfg.config.config.topology.id);
  #    # TODO: container

  #    disks =
  #      flip mapAttrs (config.disko.devices.disk or {})
  #      (_: _: {});
  #    # TODO: zfs pools from disko / fileSystems
  #    # TODO: microvm shares
  #    # TODO: container shares
  #    # TODO: OCI containers shares

  #    interfaces = let
  #      isNetwork = netDef: (netDef.matchConfig != {}) && (netDef.address != [] || netDef.DHCP != null);
  #      macsByName = mapAttrs' (flip nameValuePair) (config.networking.renameInterfacesByMac or {});
  #      netNameFor = netName: netDef:
  #        netDef.matchConfig.Name
  #        or (
  #          if netDef ? matchConfig.MACAddress && macsByName ? ${netDef.matchConfig.MACAddress}
  #          then macsByName.${netDef.matchConfig.MACAddress}
  #          else lib.trace "Could not derive network name for systemd network ${netName} on host ${config.node.name}, using unit name as fallback." netName
  #        );
  #      netMACFor = netDef: netDef.matchConfig.MACAddress or null;
  #      networks = filterAttrs (_: isNetwork) (config.systemd.network.networks or {});
  #    in
  #      flip mapAttrs' networks (netName: netDef:
  #        nameValuePair (netNameFor netName netDef) {
  #          mac = netMACFor netDef;
  #          addresses =
  #            if netDef.address != []
  #            then netDef.address
  #            else ["DHCP"];
  #        });

  #    # TODO: for each nftable zone show open ports
  #  }
  #];
}
