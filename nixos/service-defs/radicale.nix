{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Radicale";
  icon = "services.radicale";
  nixos = {
    path = "services.radicale";
    detailsFn =
      cfg:
      mkIf (cfg.settings ? server.hosts) {
        listen = {
          text = toString cfg.settings.server.hosts;
        };
      };
  };
  test = {
    config = {
      services.radicale = {
        enable = true;
        settings.server.hosts = [ "0.0.0.0:5232" ];
      };
    };
    expect = {
      name = "Radicale";
      details.listen = "0.0.0.0:5232";
    };
  };
}
