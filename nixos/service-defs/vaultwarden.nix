{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Vaultwarden";
  icon = "services.vaultwarden";
  nixos = {
    path = "services.vaultwarden";
    infoFn =
      cfg:
      let
        domain = cfg.config.domain or cfg.config.DOMAIN or null;
      in
      mkIf (domain != null) domain;
    detailsFn =
      cfg:
      let
        address = cfg.config.rocketAddress or cfg.config.ROCKET_ADDRESS or null;
        port = cfg.config.rocketPort or cfg.config.ROCKET_PORT or null;
      in
      {
        listen = mkIf (address != null && port != null) { text = "${address}:${toString port}"; };
      };
  };
  test = {
    config = {
      services.vaultwarden = {
        enable = true;
        config = {
          domain = "https://vault.example.com";
          rocketAddress = "0.0.0.0";
          rocketPort = 8222;
        };
      };
    };
    expect = {
      name = "Vaultwarden";
      info = "https://vault.example.com";
      details.listen = "0.0.0.0:8222";
    };
  };
}
