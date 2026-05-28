{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Vikunja";
  icon = "services.vikunja";
  nixos = {
    path = [
      "services"
      "vikunja"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: "${cfg.frontendScheme}://${cfg.frontendHostname}";
    detailsFn =
      cfg:
      mkIf (cfg ? address) {
        listen = {
          text = "${cfg.address}:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.vikunja = {
        enable = true;
        frontendScheme = "https";
        frontendHostname = "tasks.example.com";
      };
    };
    assertions = services: [
      {
        assertion = services.vikunja.name == "Vikunja";
        message = "expected name 'Vikunja', got '${services.vikunja.name}'";
      }
      {
        assertion = services.vikunja.info == "https://tasks.example.com";
        message = "expected info 'https://tasks.example.com', got '${services.vikunja.info}'";
      }
    ];
  };
}
