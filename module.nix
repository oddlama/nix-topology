{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    flip
    filterAttrs
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mkMerge
    mkOption
    nameValuePair
    types
    ;
in {
  options.topology = {
    id = mkOption {
      description = ''
        The attribute name in the given `nodes` which corresponds to this host.
        Please overwrite it with a unique identifier if your hostnames are not
        unique or don't reflect the name you use to refer to that node.
      '';
      default = config.networking.hostName;
      # TODO ensure unique across the board
      type = types.str;
    };

    type = mkOption {
      description = "TODO";
      default = "normal";
      type = types.enum ["normal" "microvm" "nixos-container"];
    };

    guests = mkOption {
      description = "TODO guests ids (topology.node.<name>.id) ensure exists";
      default = [];
      type = types.listOf types.str;
    };

    disks = mkOption {
      default = {};
      type = types.attrsOf (types.submodule (submod: {
        options = {
          name = mkOption {
            description = "The name of this disk";
            default = submod.config._module.args.name;
            readOnly = true;
            type = types.str;
          };
        };
      }));
    };

    interfaces = mkOption {
      description = "TODO";
      default = {};
      type = types.attrsOf (types.submodule (submod: {
        options = {
          name = mkOption {
            description = "The name of this interface";
            type = types.str;
            readOnly = true;
            default = submod.config._module.args.name;
          };

          mac = mkOption {
            description = "The MAC address of this interface, if known.";
            default = null;
            type = types.nullOr types.str;
          };

          addresses = mkOption {
            description = "The configured address(es), or a descriptive string (like DHCP).";
            type = types.listOf types.str;
          };

          network = mkOption {
            description = ''
              The global name of the attached/spanned network.
              If this is given, this interface can be shown in the network graph.
            '';
            default = null;
            type = types.nullOr types.str;
          };
        };
      }));
    };

    firewallRules = mkOption {
      description = "TODO";
      default = {};
      type = types.attrsOf (types.submodule (submod: {
        options = {
          name = mkOption {
            description = "The name of this firewall rule";
            type = types.str;
            readOnly = true;
            default = submod.config._module.args.name;
          };

          contents = mkOption {
            description = "A human readable summary of this rule's effects";
            type = types.lines;
          };
        };
      }));
    };
  };

  config.topology = mkMerge [
    {
      ################### TODO user config! #################
      id = config.node.name;
      ################### END user config   #################

      guests =
        flip mapAttrsToList (config.microvm.vms or {})
        (_: vmCfg: vmCfg.config.config.topology.id);
      # TODO: container

      disks =
        flip mapAttrs (config.disko.devices.disk or {})
        (_: _: {});
      # TODO: zfs pools from disko / fileSystems
      # TODO: microvm shares
      # TODO: container shares
      # TODO: OCI containers shares

      interfaces = let
        isNetwork = netDef: (netDef.matchConfig != {}) && (netDef.address != [] || netDef.DHCP != null);
        macsByName = mapAttrs' (flip nameValuePair) (config.networking.renameInterfacesByMac or {});
        netNameFor = netName: netDef:
          netDef.matchConfig.Name
          or (
            if netDef ? matchConfig.MACAddress && macsByName ? ${netDef.matchConfig.MACAddress}
            then macsByName.${netDef.matchConfig.MACAddress}
            else lib.trace "Could not derive network name for systemd network ${netName} on host ${config.node.name}, using unit name as fallback." netName
          );
        netMACFor = netDef: netDef.matchConfig.MACAddress or null;
        networks = filterAttrs (_: isNetwork) (config.systemd.network.networks or {});
      in
        flip mapAttrs' networks (netName: netDef:
          nameValuePair (netNameFor netName netDef) {
            mac = netMACFor netDef;
            addresses =
              if netDef.address != []
              then netDef.address
              else ["DHCP"];
          });

      # TODO: for each nftable zone show open ports
    }
  ];
}
