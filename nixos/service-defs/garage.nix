{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Garage";
  icon = "services.garage";
  nixos = {
    path = "services.garage";
    detailsFn =
      { cfg, ... }:
      let
        listen = cfg.settings.s3_api.api_bind_addr or null;
      in
      {
        listen = mkIf (listen != null) { text = listen; };
      };
  };
  test = {
    config = {
      services.garage = {
        enable = true;
        settings.s3_api.api_bind_addr = "127.0.0.1:3900";
      };
    };
    expect = {
      name = "Garage";
      details.listen = "127.0.0.1:3900";
    };
  };
}
