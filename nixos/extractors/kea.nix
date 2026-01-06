{ config, lib, ... }:
let
  inherit (lib)
    filter
    hasInfix
    imap1
    length
    listToAttrs
    mkEnableOption
    mkIf
    mkMerge
    nameValuePair
    optionalString
    ;
in
{
  options.topology.extractors.kea.enable = mkEnableOption "topology kea extractor" // {
    default = true;
  };

  config =
    let
      mkNetworks =
        version:
        let
          kea = config.services.kea."dhcp${version}";
          interfaces = filter (x: !hasInfix "*" x) (kea.settings.interfaces-config.interfaces or [ ]);
          subnets = imap1 (idx: subnet: subnet // { _topologyId = subnet.id or idx; }) (
            kea.settings."subnet${version}" or [ ]
          );
        in
        listToAttrs (
          map (
            subnet:
            nameValuePair
              "${config.topology.self.id}-kea${
                optionalString (length subnets > 1) "-${toString subnet._topologyId}"
              }"
              {
                "cidrv${version}" = mkIf (kea.enable && interfaces != [ ] && subnet.subnet != null) subnet.subnet;
              }
          ) subnets
        );

      mkInterfaces =
        version:
        let
          subnets = imap1 (idx: subnet: subnet // { _topologyId = subnet.id or idx; }) (
            config.services.kea."dhcp${version}".settings."subnet${version}" or [ ]
          );
        in
        listToAttrs (
          map (
            subnet:
            nameValuePair "${subnet.interface}" {
              network = "${config.topology.self.id}-kea${
                optionalString (length subnets > 1) "-${toString subnet._topologyId}"
              }";
            }
          ) subnets
        );
    in
    mkIf config.topology.extractors.kea.enable {
      topology.networks = mkMerge (
        map mkNetworks [
          "4"
          "6"
        ]
      );

      # Do not use topology.self.interfaces here to prevent inclusion of a mkMerge which cannot be
      # detected by the network propagator currently.
      topology.nodes.${config.topology.id}.interfaces = mkMerge (
        map mkInterfaces [
          "4"
          "6"
        ]
      );
    };
}
