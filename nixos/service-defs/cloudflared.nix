{ lib }:
let
  inherit (lib)
    attrValues
    filterAttrs
    isString
    mapAttrs
    mergeAttrsList
    ;
in
{
  name = "Cloudflared";
  icon = "services.cloudflared";
  nixos = {
    path = "services.cloudflared";
    detailsFn =
      { cfg, ... }:
      let
        # A rule is either the service itself, or a set that may leave it out
        serviceOf = rule: if isString rule then rule else rule.service;
        rules = mergeAttrsList (map (tunnel: tunnel.ingress) (attrValues cfg.tunnels));
      in
      mapAttrs (_: service: { text = service; }) (
        filterAttrs (_: service: service != null) (mapAttrs (_: serviceOf) rules)
      );
  };
  test = {
    config = {
      services.cloudflared = {
        enable = true;
        tunnels."00000000-0000-0000-0000-000000000000" = {
          credentialsFile = "/run/secrets/cloudflared";
          default = "http_status:404";
          ingress = {
            "app.example.com" = "http://localhost:3000";
            "git.example.com".service = "http://localhost:3001";
          };
        };
      };
    };
    expect = {
      name = "Cloudflared";
      details = {
        "app.example.com" = "http://localhost:3000";
        "git.example.com" = "http://localhost:3001";
      };
    };
  };
}
