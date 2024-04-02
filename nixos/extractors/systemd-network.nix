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
    filter
    flatten
    flip
    hasInfix
    hasPrefix
    init
    length
    listToAttrs
    mapAttrsToList
    mkDefault
    recursiveUpdate
    mkEnableOption
    mkIf
    mkMerge
    nameValuePair
    optional
    optionals
    splitString
    tail
    toList
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
      ++ flatten (
        flip mapAttrsToList config.systemd.network.networks (
          unit: network: let
            # Some attributes like Name accept lists with a single entry
            firstValue = x: builtins.head (toList x);
            nameOrNull =
              if network ? matchConfig.Name
              then firstValue network.matchConfig.Name
              else null;

            linkMacToName = listToAttrs (flatten (flip map (attrValues config.systemd.network.links) (
              linkCfg:
                optional (linkCfg ? matchConfig.MACAddress && linkCfg ? linkConfig.Name) (
                  nameValuePair linkCfg.matchConfig.MACAddress (firstValue linkCfg.linkConfig.Name)
                )
            )));

            # FIXME: TODO renameInterfacesByMac is not a standard option! It's not an issue here but should proabaly not be used anyway.
            extraMacToName = listToAttrs (mapAttrsToList (k: v: nameValuePair v k) (config.networking.renameInterfacesByMac or {}));

            macToName = recursiveUpdate linkMacToName extraMacToName;

            nameFromMac =
              optional (network ? matchConfig.MACAddress && macToName ? ${network.matchConfig.MACAddress})
              macToName.${network.matchConfig.MACAddress};

            nameFromNetdev =
              optional (
                (nameOrNull != null)
                && flip any (attrValues config.systemd.network.netdevs) (x:
                  (x ? netdevConfig.Name)
                  && (firstValue x.netdevConfig.Name) == nameOrNull)
              )
              nameOrNull;

            # Fallback name is either matchConfig.Name if it doesn't contain a wildcard,
            # or the unit name if we match by mac address.
            fallbackNames =
              optional (nameOrNull != null && !hasInfix "*" nameOrNull) nameOrNull
              ++ optional (network ? matchConfig.MACAddress) unit;

            interfaceName = builtins.head (nameFromMac ++ nameFromNetdev ++ fallbackNames ++ [null]);

            # Find out if the interface is bridged to another interface
            linesStartingWith = prefix: lines: filter (hasPrefix prefix) (splitString "\n" lines);
            kvValue = str: concatStringsSep "=" (tail (splitString "=" str));
            assignmentsFor = key: lines: map kvValue (linesStartingWith key lines);

            macvtapTo = assignmentsFor "MACVTAP=" network.extraConfig;
            macvlanTo = assignmentsFor "MACVLAN=" network.extraConfig;
            bridgeTo = network.bridge ++ (toList (network.networkConfig.Bridge or []));
            allBridges = macvtapTo ++ macvlanTo ++ bridgeTo;
          in
            optionals (interfaceName != null) (
              [
                {
                  ${interfaceName} = {
                    mac = mkIf ((network.matchConfig.MACAddress or null) != null) network.matchConfig.MACAddress;
                    addresses = map removeCidrMask (network.address ++ (network.networkConfig.Address or []));
                    gateways = network.gateway ++ (network.networkConfig.Gateway or []);
                  };
                }
              ]
              ++ flip map allBridges (
                bridged: {
                  ${interfaceName}.sharesNetworkWith = [(x: x == bridged)];
                  ${bridged}.sharesNetworkWith = [(x: x == interfaceName)];
                }
              )
            )
        )
      )
    );
  };
}
