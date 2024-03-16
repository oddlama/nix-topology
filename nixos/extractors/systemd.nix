{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    any
    attrValues
    concatLists
    flip
    mapAttrsToList
    mkDefault
    mkIf
    mkMerge
    optional
    ;
in {
  config = mkIf config.systemd.network.enable {
    topology.self.interfaces = mkMerge (
      # Create interfaces based on systemd.network.netdevs
      concatLists (
        flip mapAttrsToList config.systemd.network.netdevs (
          _unit: netdev:
            optional (netdev ? netdevConfig.Name) {
              ${netdev.netdevConfig.Name} = {
                virtual = mkDefault true;
              };
            }
        )
      )
      # Add interface configuration based on systemd.network.networks
      ++ concatLists (
        flip mapAttrsToList config.systemd.network.networks (
          _unit: network: let
            # FIXME: TODO renameInterfacesByMac is not a standard option!
            nameFromMac =
              optional (network ? matchConfig.MACAddress && config.networking.renameInterfacesByMac ? ${network.matchConfig.MACAddress})
              config.networking.renameInterfacesByMac.${network.matchConfig.MACAddress};

            nameFromNetdev =
              optional (
                (network ? matchConfig.Name)
                && flip any (attrValues config.systemd.network.netdevs) (x:
                  (x ? netdevConfig.Name)
                  && x.netdevConfig.Name == network.matchConfig.Name)
              )
              network.matchConfig.Name;

            interfaceName = builtins.head (nameFromMac ++ nameFromNetdev ++ [null]);
          in
            optional (interfaceName != null) {
              ${interfaceName} = {
                mac = network.matchConfig.MACAddress or null;
                addresses = network.address ++ (network.networkConfig.Address or []);
                gateways = network.gateway ++ (network.networkConfig.Gateway or []);
              };
            }
        )
      )
    );
  };
}
