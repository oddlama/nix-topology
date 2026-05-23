{ lib }:
let
  inherit (lib) mkIf;
  replaceAny = addr: replacement: if addr == "any" then replacement else addr;
in
{
  name = "Bind9";
  icon = "services.bind9";
  nixos = {
    path = "services.bind";
    detailsFn = cfg: {
      listen_ipv4.text = toString (
        map (address: "${replaceAny address "0.0.0.0"}:${toString cfg.listenOnPort}") cfg.listenOn
      );
      listen_ipv6 = mkIf (!cfg.ipv4Only) {
        text = toString (
          map (address: "${replaceAny address "[::]"}:${toString cfg.listenOnIpv6Port}") cfg.listenOnIpv6
        );
      };
    };
  };
}
