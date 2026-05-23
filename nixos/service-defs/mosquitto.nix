{ lib }:
let
  inherit (lib)
    flip
    imap0
    listToAttrs
    map
    ;
in
{
  name = "Mosquitto";
  icon = "services.mosquitto";
  nixos = {
    path = "services.mosquitto";
    detailsFn =
      cfg:
      listToAttrs (
        flip imap0
          (flip map cfg.listeners (l: rec {
            address = if l.address == null then "[::]" else l.address;
            listen = if l.port == 0 then address else "${address}:${toString l.port}";
          }))
          (
            i: l: {
              name = "listen[${toString i}]";
              value = {
                text = l.listen;
              };
            }
          )
      );
  };
  test = {
    config = {
      services.mosquitto = {
        enable = true;
        listeners = [
          {
            address = "0.0.0.0";
            port = 1883;
          }
        ];
      };
    };
    expect = {
      name = "Mosquitto";
      details."listen[0]" = "0.0.0.0:1883";
    };
  };
}
