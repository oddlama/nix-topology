{ lib }:
let
  inherit (lib) map;
in
{
  name = "Hickory DNS";
  icon = "services.hickory-dns";
  nixos = {
    path = "services.hickory-dns";
    detailsFn = cfg: {
      listen_ipv4 = {
        text = toString (
          map (addr: "${addr}:${toString cfg.settings.listen_port}") cfg.settings.listen_addrs_ipv4
        );
      };
      listen_ipv6 = {
        text = toString (
          map (addr: "${addr}:${toString cfg.settings.listen_port}") cfg.settings.listen_addrs_ipv6
        );
      };
    };
  };
  test = {
    config = {
      services.hickory-dns = {
        enable = true;
        settings = {
          listen_port = 53;
          listen_addrs_ipv4 = [
            "127.0.0.1"
            "10.0.0.1"
          ];
          listen_addrs_ipv6 = [ "::1" ];
          zones = { };
        };
      };
    };
    expect = {
      name = "Hickory DNS";
      details.listen_ipv4 = "127.0.0.1:53 10.0.0.1:53";
      details.listen_ipv6 = "::1:53";
    };
  };
}
