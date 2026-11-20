{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Attic";
  icon = "services.not-available";
  nixos = {
    path = "services.atticd";
    infoFn = { cfg, ... }: cfg.settings.api-endpoint or null;
    detailsFn =
      { cfg, ... }:
      let
        listen = cfg.settings.listen or null;
      in
      {
        listen = mkIf (listen != null) { text = listen; };
      };
  };
  test = {
    config = {
      services.atticd = {
        enable = true;
        settings = {
          listen = "127.0.0.1:8080";
          api-endpoint = "https://cache.example.com/";
        };
      };
    };
    expect = {
      name = "Attic";
      info = "https://cache.example.com/";
      details.listen = "127.0.0.1:8080";
    };
  };
}
