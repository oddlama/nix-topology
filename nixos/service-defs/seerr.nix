{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Seerr";
  icon = "services.seerr";
  nixos = {
    path = "services.seerr";
    detailsFn = { cfg, ... }: {
      listen = mkIf cfg.openFirewall { text = "0.0.0.0:${toString cfg.port}"; };
    };
  };
  oci.repos = [
    "jellyseerr"
    "seerr"
  ];
  test = {
    config = {
      services.seerr = {
        enable = true;
        openFirewall = true;
        port = 5055;
      };
    };
    expect = {
      name = "Seerr";
      details.listen = "0.0.0.0:5055";
    };
  };
}
