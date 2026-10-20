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
    path = "services.caddy";
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
    expect = {
      name = "Caddy";
      details."app.example.com" = "localhost:3000";
    };
  };
}
