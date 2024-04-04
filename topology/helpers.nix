lib: let
  inherit
    (lib)
    concatMap
    elem
    flip
    mapAttrsToList
    mkIf
    mkMerge
    toList
    ;
in rec {
  # Finally we found it, the one-and-only true cloud.
  mkInternet = {connections ? [], ...}: {
    name = "Internet";
    deviceType = "internet";
    hardware.image = ../icons/devices/cloud.svg;
    interfaces."*".physicalConnections = toList connections;
  };

  mkConnection = node: interface: {inherit node interface;};
  mkConnectionRev = node: interface: {
    inherit node interface;
    renderer.reverse = true;
  };

  mkSwitch = name: {
    info ? null,
    image ? null,
    deviceType ? "switch",
    interfaceGroups ? [],
    connections ? {},
    ...
  } @ args:
    mkMerge [
      (builtins.removeAttrs args ["info" "image" "interfaceGroups" "connections"])
      {
        inherit name deviceType;
        hardware = {
          info = mkIf (info != null) info;
          image = mkIf (image != null) image;
        };
        interfaces = mkMerge (
          flip mapAttrsToList connections (interface: conns: {
            ${interface}.physicalConnections = toList conns;
          })
          ++ flip concatMap interfaceGroups (
            group:
              flip map group (
                interface: {
                  ${interface}.sharesNetworkWith = [(x: elem x group)];
                }
              )
          )
        );
      }
    ];

  mkRouter = name: args:
    mkSwitch name (args
      // {
        deviceType = "router";
      });

  mkDevice = name: args:
    mkSwitch name (args
      // {
        deviceType = "device";
      });
}
