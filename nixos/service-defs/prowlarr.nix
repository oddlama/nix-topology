{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Prowlarr";
  icon = "services.prowlarr";
  nixos = {
    path = "services.prowlarr";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:9696";
        };
      };
  };
  test = {
    config = {
      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };
    };
    expect = {
      name = "Prowlarr";
      details.listen = "0.0.0.0:9696";
    };
  };
}
