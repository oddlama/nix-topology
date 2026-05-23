{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Vaultwarden";
  icon = "services.vaultwarden";
  nixos = {
    path = [
      "services"
      "vaultwarden"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.vaultwarden.name == "Vaultwarden";
        message = "expected name 'Vaultwarden', got '${services.vaultwarden.name}'";
      }
      {
        assertion = services.vaultwarden.info == "https://vault.example.com";
        message = "expected info 'https://vault.example.com', got '${services.vaultwarden.info}'";
      }
      {
        assertion = services.vaultwarden.details.listen.text == "0.0.0.0:8222";
        message = "expected listen '0.0.0.0:8222', got '${services.vaultwarden.details.listen.text}'";
      }
    ];
  };
}
