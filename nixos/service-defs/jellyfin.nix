{ lib }:
let
  inherit (lib) listToAttrs mapAttrsToList optionalAttrs;
in
{
  name = "Jellyfin";
  icon = "services.jellyfin";
  nixos = {
    path = "services.jellyfin";
    detailsFn =
      cfg:
      listToAttrs (
        mapAttrsToList
          (n: v: {
            name = "listen.${n}";
            value = {
              text = "0.0.0.0:${toString v}";
            };
          })
          (
            optionalAttrs cfg.openFirewall {
              http = 8096;
              https = 8920;
              service-discovery = 1900;
              client-discovery = 7359;
            }
          )
      );
  };
  test = {
    config = {
      services.jellyfin = {
        enable = true;
        openFirewall = true;
      };
    };
    expect = {
      name = "Jellyfin";
      details."listen.http" = "0.0.0.0:8096";
      details."listen.https" = "0.0.0.0:8920";
      details."listen.service-discovery" = "0.0.0.0:1900";
      details."listen.client-discovery" = "0.0.0.0:7359";
    };
  };
}
