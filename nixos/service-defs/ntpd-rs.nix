{ lib }:
let
  inherit (lib) imap1 listToAttrs;
in
{
  name = "NTPd-rs";
  icon = "services.ntpd-rs";
  nixos = {
    path = "services.ntpd-rs";
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
    # Only shown when acting as an NTP server
    minimalConfig = {
      services.ntpd-rs = {
        enable = true;
        settings.server = [ { listen = "0.0.0.0:123"; } ];
      };
    };
    config = {
      services.ntpd-rs = {
        enable = true;
        settings.server = [
          { listen = "0.0.0.0:123"; }
          { listen = "127.0.0.1:123"; }
        ];
      };
    };
    expect = {
      name = "NTPd-rs";
      details."server 1 listen" = "0.0.0.0:123";
      details."server 2 listen" = "127.0.0.1:123";
    };
  };
}
