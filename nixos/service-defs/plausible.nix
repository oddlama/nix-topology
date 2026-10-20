{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Plausible";
  icon = "services.plausible";
  nixos = {
    path = "services.plausible";
    detailsFn =
      cfg:
      let
        listenAddress = cfg.server.listenAddress or null;
        port = cfg.server.port or null;
      in
      mkIf (listenAddress != null && port != null) {
        listen = {
          text = "${listenAddress}:${toString port}";
        };
      };
    infoFn = cfg: cfg.server.baseUrl;
  };
  test = {
    minimalConfig = {
      services.plausible = {
        enable = true;
        server = {
          baseUrl = "https://plausible.example.com";
          secretKeybaseFile = "/dev/null";
        };
      };
    };
    config = {
      services.plausible = {
        enable = true;
        server = {
          listenAddress = "0.0.0.0";
          port = 8000;
          baseUrl = "https://plausible.example.com";
          secretKeybaseFile = "/dev/null";
        };
      };
    };
    expect = {
      name = "Plausible";
      info = "https://plausible.example.com";
      details.listen = "0.0.0.0:8000";
    };
  };
}
