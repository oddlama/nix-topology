{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Anki";
  icon = "services.anki";
  nixos = {
    path = "services.anki-sync-server";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.address}:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.anki-sync-server = {
        enable = true;
        openFirewall = true;
        address = "0.0.0.0";
        port = 27701;
      };
    };
    expect = {
      name = "Anki";
      details.listen = "0.0.0.0:27701";
    };
  };
}
