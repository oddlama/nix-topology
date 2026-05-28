{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Seerr";
  icon = "services.seerr";
  nixos = {
    path = [
      "services"
      "jellyseerr"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf (cfg.openFirewall or false) {
        listen = {
          text = "0.0.0.0:${toString cfg.port}";
        };
      };
  };
}
