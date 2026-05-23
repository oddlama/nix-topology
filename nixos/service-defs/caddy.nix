{ lib }:
let
  inherit (lib)
    concatStringsSep
    filter
    genAttrs
    hasPrefix
    map
    mapAttrsToList
    removePrefix
    removeSuffix
    splitString
    ;
in
{
  name = "Caddy";
  icon = "services.caddy";
  nixos = {
    path = [
      "services"
      "caddy"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      genAttrs (mapAttrsToList (name: _: name) (cfg.virtualHosts or { })) (name: {
        text = concatStringsSep " " (
          map (line: removePrefix "reverse_proxy " (removeSuffix " {" line)) (
            filter (line: hasPrefix "reverse_proxy " line) (
              splitString "\n" (cfg.virtualHosts.${name}.extraConfig or "")
            )
          )
        );
      });
  };
  test = {
    config = {
      services.caddy = {
        enable = true;
        virtualHosts."app.example.com" = {
          extraConfig = "reverse_proxy localhost:3000";
        };
      };
    };
    assertions = services: [
      {
        assertion = services.caddy.name == "Caddy";
        message = "expected name 'Caddy', got '${services.caddy.name}'";
      }
      {
        assertion = services.caddy.details."app.example.com".text == "localhost:3000";
        message = "expected detail 'localhost:3000', got '${
          services.caddy.details."app.example.com".text
        }'";
      }
    ];
  };
}
