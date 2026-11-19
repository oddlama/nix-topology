{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Immich Public Proxy";
  icon = "services.immich-public-proxy";
  nixos = {
    path = "services.immich-public-proxy";
    # The external domain of an Immich instance on the same host. `services.immich.settings`
    # is null unless set, and the proxy usually runs on a different host than Immich.
    infoFn = { config, ... }: config.services.immich.settings.server.externalDomain or "";
    detailsFn = { cfg, ... }: {
      listen = mkIf cfg.openFirewall { text = "localhost:${toString cfg.port}"; };
    };
  };
  oci.repos = [ "immich-public-proxy" ];
  test = {
    # Without Immich on the same host
    minimalConfig = {
      services.immich-public-proxy = {
        enable = true;
        immichUrl = "http://immich.internal:2283";
      };
    };
    config = {
      services.immich-public-proxy = {
        enable = true;
        immichUrl = "http://localhost:2283";
        openFirewall = true;
        port = 3000;
      };
      services.immich = {
        enable = true;
        settings.server.externalDomain = "https://photos.example.com";
      };
    };
    expect = {
      name = "Immich Public Proxy";
      info = "https://photos.example.com";
      details.listen = "localhost:3000";
    };
  };
}
