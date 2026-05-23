{ lib }:
let
  inherit (lib) listToAttrs mapAttrsToList;
in
{
  name = "Blocky";
  icon = "services.blocky";
  nixos = {
    path = "services.blocky";
    detailsFn =
      cfg:
      listToAttrs (
        mapAttrsToList (n: v: {
          name = "listen.${n}";
          value = {
            text = toString v;
          };
        }) (cfg.settings.ports or { })
      );
  };
  test = {
    config = {
      services.blocky = {
        enable = true;
        settings = {
          ports = {
            dns = 53;
            http = 4000;
          };
        };
      };
    };
    expect = {
      name = "Blocky";
      details."listen.dns" = "53";
      details."listen.http" = "4000";
    };
  };
}
