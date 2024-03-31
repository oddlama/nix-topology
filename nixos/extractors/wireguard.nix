{
  config,
  lib,
  inputs ? {},
  ...
}: let
  inherit
    (lib)
    flip
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    filter
    ;

  headOrNull = xs:
    if xs == []
    then null
    else builtins.head xs;

  networkId = wgName: "wireguard-${wgName}";
in {
  options.topology.extractors.wireguard.enable = mkEnableOption "topology wireguard extractor" // {default = true;};

  config = mkIf (config.topology.extractors.wireguard.enable && config ? wireguard) {
    # Create networks (this will be duplicated by each node,
    # but it doesn't matter and will be merged anyway)
    topology.networks = mkMerge (
      flip mapAttrsToList config.wireguard (
        wgName: _: let
          inherit (lib.wireguard inputs wgName) networkCidrs;
        in {
          ${networkId wgName} = {
            name = mkDefault "Wireguard network '${wgName}'";
            icon = "interfaces.wireguard";
            cidrv4 = headOrNull (filter lib.net.ip.isv4 networkCidrs);
            cidrv6 = headOrNull (filter lib.net.ip.isv6 networkCidrs);
          };
        }
      )
    );

    # Assign network and physical connections to related interfaces
    topology.self.interfaces = mkMerge (
      flip mapAttrsToList config.wireguard (
        wgName: wgCfg: let
          inherit
            (lib.wireguard inputs wgName)
            participatingServerNodes
            wgCfgOf
            ;

          isServer = wgCfg.server.host != null;
          filterSelf = filter (x: x != config.node.name);

          # The list of peers that are "physically" connected in the wireguard network,
          # meaning they communicate directly with each other.
          connectedPeers =
            if isServer
            then
              # Other servers in the same network
              filterSelf participatingServerNodes
            else [wgCfg.client.via];
        in {
          ${wgCfg.linkName} = {
            network = networkId wgName;
            virtual = true;
            renderer.hidePhysicalConnections = true;
            physicalConnections = flip map connectedPeers (peer: {
              node = inputs.self.nodes.${peer}.config.topology.id;
              interface = (wgCfgOf peer).linkName;
            });
          };
        }
      )
    );
  };
}
