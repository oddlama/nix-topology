{ lib }:
let
  inherit (lib)
    attrNames
    elemAt
    length
    mapAttrsToList
    mkMerge
    ;
in
{
  name = "Traefik";
  icon = "services.traefik";
  nixos = {
    path = "services.traefik";
    detailsFn =
      cfg:
      let
        dynCfg = cfg.dynamicConfigOptions;
        routers = dynCfg.http.routers or { };
      in
      if length (attrNames routers) > 0 then
        let
          formatOutput = mapAttrsToList (
            routerName: routerAttrs:
            let
              getServiceUrl =
                serviceName:
                let
                  service = dynCfg.http.services.${toString serviceName}.loadBalancer.servers or [ ];
                in
                if length service > 0 then (elemAt service 0).url else "invalid service";
              passText = toString (getServiceUrl routerAttrs.service);
            in
            {
              ${toString routerName} = {
                text = passText;
              };
            }
          ) routers;
        in
        mkMerge formatOutput
      else
        { };
  };
  test = {
    config = {
      services.traefik = {
        enable = true;
        dynamicConfigOptions.http = {
          routers.myapp = {
            rule = "Host(`app.example.com`)";
            service = "myapp";
          };
          services.myapp.loadBalancer.servers = [ { url = "http://127.0.0.1:8080"; } ];
        };
      };
    };
    expect = {
      name = "Traefik";
      details.myapp = "http://127.0.0.1:8080";
    };
  };
}
