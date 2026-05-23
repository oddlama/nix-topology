{ lib }:
let
  inherit (lib) imap1 listToAttrs;
in
{
  name = "NTPd-rs";
  icon = "services.ntpd-rs";
  nixos = {
    path = [
      "services"
      "ntpd-rs"
    ];
    enabled = cfg: cfg.enable && (cfg.settings.server or [ ]) != [ ];
    detailsFn =
      cfg:
      let
        ntpServers = cfg.settings.server or [ ];
      in
      listToAttrs (
        imap1 (i: server: {
          name = "server ${toString i} listen";
          value.text = server.listen;
        }) ntpServers
      );
  };
  test = {
    config = {
      services.ntpd-rs = {
        enable = true;
        settings.server = [
          { listen = "0.0.0.0:123"; }
          { listen = "127.0.0.1:123"; }
        ];
      };
    };
    assertions = services: [
      {
        assertion = services.ntpd-rs.name == "NTPd-rs";
        message = "expected name 'NTPd-rs', got '${services.ntpd-rs.name}'";
      }
      {
        assertion = services.ntpd-rs.details."server 1 listen".text == "0.0.0.0:123";
        message = "expected server 1 listen '0.0.0.0:123', got '${
          services.ntpd-rs.details."server 1 listen".text
        }'";
      }
      {
        assertion = services.ntpd-rs.details."server 2 listen".text == "127.0.0.1:123";
        message = "expected server 2 listen '127.0.0.1:123', got '${
          services.ntpd-rs.details."server 2 listen".text
        }'";
      }
    ];
  };
}
