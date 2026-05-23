{ lib }:
let
  inherit (lib)
    forEach
    head
    listToAttrs
    removePrefix
    splitString
    tail
    ;
in
{
  name = "Dnsmasq";
  icon = "services.dnsmasq";
  nixos = {
    path = "services.dnsmasq";
    detailsFn =
      cfg:
      let
        addresses = cfg.settings.address or [ ];
      in
      listToAttrs (
        forEach (forEach addresses (x: splitString "/" (removePrefix "/" x))) (x: {
          name = head x;
          value = {
            text = head (tail x);
          };
        })
      );
  };
  test = {
    config = {
      services.dnsmasq = {
        enable = true;
        settings = {
          address = [ "/myhost.local/192.168.1.10" ];
        };
      };
    };
    expect = {
      name = "Dnsmasq";
      details."myhost.local" = "192.168.1.10";
    };
  };
}
