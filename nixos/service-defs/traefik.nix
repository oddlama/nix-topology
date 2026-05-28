{ lib }:
let
  inherit (lib)
    attrNames
    elemAt
    length
    mapAttrsToList
    mkIf
    mkMerge
    ;
in
{
  name = "Traefik";
  icon = "services.traefik";
  nixos = {
    path = [
      "services"
      "traefik"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        dynCfg = cfg.dynamicConfigOptions;
      in
      mkIf (length (attrNames dynCfg) > 0) (
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
          ) dynCfg.http.routers;
        in
        mkMerge formatOutput
      );
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
    assertions = services: [
      {
        assertion = services.traefik.name == "Traefik";
        message = "expected name 'Traefik', got '${services.traefik.name}'";
      }
      {
        assertion = services.traefik.details.myapp.text == "http://127.0.0.1:8080";
        message = "expected myapp 'http://127.0.0.1:8080', got '${services.traefik.details.myapp.text}'";
      }
    ];
  };
}
