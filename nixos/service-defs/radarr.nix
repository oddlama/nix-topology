{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Radarr";
  icon = "services.radarr";
  nixos = {
    path = "services.radarr";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:7878";
        };
      };
  };
  test = {
    config = {
      services.radarr = {
        enable = true;
        openFirewall = true;
      };
    };
    expect = {
      name = "Radarr";
      details.listen = "0.0.0.0:7878";
    };
  };
}
