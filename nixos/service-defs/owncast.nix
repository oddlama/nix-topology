{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Owncast";
  icon = "services.owncast";
  nixos = {
    path = "services.owncast";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.listen}:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.owncast = {
        enable = true;
        openFirewall = true;
        listen = "0.0.0.0";
        port = 8080;
      };
    };
    expect = {
      name = "Owncast";
      details.listen = "0.0.0.0:8080";
    };
  };
}
