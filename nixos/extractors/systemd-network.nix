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
    concatStringsSep
    flip
    init
    length
    listToAttrs
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    nameValuePair
    optional
    splitString
    ;

  removeCidrMask = x: let
    toks = splitString "/" x;
  in
    if length toks > 1
    then concatStringsSep "/" (init toks)
    else builtins.head toks;
in {
  options.topology.extractors.systemd-network.enable = mkEnableOption "topology systemd-network extractor" // {default = true;};

  config = mkIf (config.topology.extractors.systemd-network.enable && config.systemd.network.enable) {
    topology.self.interfaces = mkMerge (
      # Create interfaces based on systemd.network.netdevs
      concatLists (
        flip mapAttrsToList config.systemd.network.netdevs (
          _unit: netdev:
            optional (netdev ? netdevConfig.Name) {
              ${netdev.netdevConfig.Name} = {
                virtual = mkDefault true;
                type = mkIf (netdev ? netdevConfig.Kind) netdev.netdevConfig.Kind;
              };
            }
        )
      )
      # Add interface configuration based on systemd.network.networks
      ++ concatLists (
        flip mapAttrsToList config.systemd.network.networks (
          _unit: network: let
            # FIXME: TODO renameInterfacesByMac is not a standard option!
            macToName = listToAttrs (mapAttrsToList (k: v: nameValuePair v k) config.networking.renameInterfacesByMac);

            nameFromMac =
              optional (network ? matchConfig.MACAddress && macToName ? ${network.matchConfig.MACAddress})
              macToName.${network.matchConfig.MACAddress};

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
                addresses = map removeCidrMask (network.address ++ (network.networkConfig.Address or []));
                gateways = network.gateway ++ (network.networkConfig.Gateway or []);
              };
            }
        )
      )
    );
  };
}
