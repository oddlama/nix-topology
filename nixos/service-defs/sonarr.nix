{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Sonarr";
  icon = "services.sonarr";
  nixos = {
    path = "services.sonarr";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:8989";
        };
      };
  };
  test = {
    config = {
      services.sonarr = {
        enable = true;
        openFirewall = true;
      };
    };
    expect = {
      name = "Sonarr";
      details.listen = "0.0.0.0:8989";
    };
  };
}
