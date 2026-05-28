{ lib }:
let
  inherit (lib) listToAttrs mapAttrsToList optionalAttrs;
in
{
  name = "Jellyfin";
  icon = "services.jellyfin";
  nixos = {
    path = [
      "services"
      "jellyfin"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.jellyfin.name == "Jellyfin";
        message = "expected name 'Jellyfin', got '${services.jellyfin.name}'";
      }
      {
        assertion = services.jellyfin.details."listen.http".text == "0.0.0.0:8096";
        message = "expected listen.http '0.0.0.0:8096', got '${
          services.jellyfin.details."listen.http".text
        }'";
      }
      {
        assertion = services.jellyfin.details."listen.https".text == "0.0.0.0:8920";
        message = "expected listen.https '0.0.0.0:8920', got '${
          services.jellyfin.details."listen.https".text
        }'";
      }
      {
        assertion = services.jellyfin.details."listen.service-discovery".text == "0.0.0.0:1900";
        message = "expected listen.service-discovery '0.0.0.0:1900', got '${
          services.jellyfin.details."listen.service-discovery".text
        }'";
      }
      {
        assertion = services.jellyfin.details."listen.client-discovery".text == "0.0.0.0:7359";
        message = "expected listen.client-discovery '0.0.0.0:7359', got '${
          services.jellyfin.details."listen.client-discovery".text
        }'";
      }
    ];
  };
}
