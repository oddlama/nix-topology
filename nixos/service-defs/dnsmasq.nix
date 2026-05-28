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
    path = [
      "services"
      "dnsmasq"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.dnsmasq.name == "Dnsmasq";
        message = "expected name 'Dnsmasq', got '${services.dnsmasq.name}'";
      }
      {
        assertion = services.dnsmasq.details."myhost.local".text == "192.168.1.10";
        message = "expected detail 'myhost.local' = '192.168.1.10', got '${
          services.dnsmasq.details."myhost.local".text
        }'";
      }
    ];
  };
}
