{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    const
    filter
    genAttrs
    hasInfix
    mkEnableOption
    mkIf
    ;
in {
  options.topology.extractors.kea.enable = mkEnableOption "topology kea extractor" // {default = true;};

  config = let
    interfaces = filter (x: !hasInfix "*" x) config.services.kea.dhcp4.settings.interfaces-config.interfaces or [];
    headOrNull = xs:
      if xs == []
      then null
      else builtins.head xs;
    subnet = headOrNull (map (x: x.subnet) (config.services.kea.dhcp4.settings.subnet4 or []));
    netName = "${config.topology.self.id}-kea";
  in
    mkIf (config.topology.extractors.kea.enable && config.services.kea.dhcp4.enable && interfaces != [] && subnet != null) {
      topology.networks.${netName} = {
        cidrv4 = subnet;
      };

      topology.self.interfaces = genAttrs interfaces (const {network = netName;});
    };
}
