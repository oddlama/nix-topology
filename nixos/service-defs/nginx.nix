{ lib }:
let
  inherit (lib)
    attrNames
    flatten
    flip
    mapAttrsToList
    mkMerge
    optional
    replaceStrings
    ;
in
{
  name = "NGINX";
  icon = "services.nginx";
  nixos = {
    path = "services.nginx";
    detailsFn =
      cfg:
      let
        reverseProxies = flatten (
          flip mapAttrsToList (cfg.virtualHosts or { }) (
            server: vh:
            flip mapAttrsToList (vh.locations or { }) (
              path: location:
              let
                upstreamName = replaceStrings [ "http://" "https://" ] [ "" "" ] location.proxyPass;
                passTo =
                  if (cfg.upstreams or { }) ? ${upstreamName} then
                    toString (attrNames cfg.upstreams.${upstreamName}.servers)
                  else
                    location.proxyPass;
              in
              optional (path == "/" && location.proxyPass != null) {
                ${server} = {
                  text = passTo;
                };
              }
            )
          )
        );
      in
      mkMerge reverseProxies;
  };
  test = {
    config = {
      services.nginx = {
        enable = true;
        virtualHosts."example.com" = {
          locations."/".proxyPass = "http://127.0.0.1:3000";
        };
      };
    };
    expect = {
      name = "NGINX";
      details."example.com" = "http://127.0.0.1:3000";
    };
  };
}
