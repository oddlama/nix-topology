{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Lidarr";
  icon = "services.lidarr";
  nixos = {
    path = "services.lidarr";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:8686";
        };
      };
  };
  test = {
    config = {
      services.lidarr = {
        enable = true;
        openFirewall = true;
      };
    };
    expect = {
      name = "Lidarr";
      details.listen = "0.0.0.0:8686";
    };
  };
}
