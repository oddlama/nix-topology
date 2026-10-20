{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Vikunja";
  icon = "services.vikunja";
  nixos = {
    path = "services.vikunja";
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
    minimalConfig = {
      services.vikunja = {
        enable = true;
        frontendScheme = "https";
        frontendHostname = "tasks.example.com";
      };
    };
    config = {
      services.vikunja = {
        enable = true;
        frontendScheme = "https";
        frontendHostname = "tasks.example.com";
      };
    };
    expect = {
      name = "Vikunja";
      info = "https://tasks.example.com";
    };
  };
}
