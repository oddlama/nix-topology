{ config, lib, ... }:
let
  inherit (lib)
    filter
    genAttrs
    hasInfix
    mkEnableOption
    mkIf
    forEach
    const
    ;
in
{
  options.topology.extractors.networking.interface.enable =
    mkEnableOption "topology networking.interface extractor"
    // {
      default = true;
    };

  config =
    let
      interfaces = filter (x: !hasInfix "*" x) (builtins.attrNames config.networking.interfaces);
    in
    mkIf
      (
        config.topology.extractors.networking.interface.enable
        && interfaces != [ ]
        && !config.networking.useNetworkd
      )
      {
        topology.self.interfaces = genAttrs interfaces (
          interface:
          (const {
            addresses =
              let
                addrs =
                  (forEach config.networking.interfaces.${interface}.ipv4.addresses (x: x.address) # Returns the extracted address (took me FOREVER to realize it was a list of attrs, not of strings)
                  )
                  ++ (forEach config.networking.interfaces.${interface}.ipv6.addresses (x: x.address) # Same here
                  );
              in
              if addrs != [ ] then addrs else [ "DHCP" ];

            mac = config.networking.interfaces.${interface}.macAddress;
          })
        );
      };
}
