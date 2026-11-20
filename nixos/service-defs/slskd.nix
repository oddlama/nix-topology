{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "slskd";
  icon = "services.slskd";
  nixos = {
    path = "services.slskd";
    infoFn = { cfg, ... }: cfg.domain;
    detailsFn =
      { cfg, ... }:
      let
        address = cfg.settings.web.ip_address or null;
        port = cfg.settings.web.port or null;
      in
      {
        listen = mkIf (address != null && port != null) { text = "${address}:${toString port}"; };
      };
  };
  test = {
    config = {
      services.slskd = {
        enable = true;
        domain = "slskd.example.com";
        environmentFile = "/run/secrets/slskd";
        settings.web = {
          ip_address = "127.0.0.1";
          port = 5030;
        };
      };
    };
    expect = {
      name = "slskd";
      info = "slskd.example.com";
      details.listen = "127.0.0.1:5030";
    };
  };
}
