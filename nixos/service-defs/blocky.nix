{ lib }:
let
  inherit (lib) listToAttrs mapAttrsToList;
in
{
  name = "Blocky";
  icon = "services.blocky";
  nixos = {
    path = [
      "services"
      "blocky"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.blocky.name == "Blocky";
        message = "expected name 'Blocky', got '${services.blocky.name}'";
      }
      {
        assertion = services.blocky.details."listen.dns".text == "53";
        message = "expected listen.dns '53', got '${services.blocky.details."listen.dns".text}'";
      }
      {
        assertion = services.blocky.details."listen.http".text == "4000";
        message = "expected listen.http '4000', got '${services.blocky.details."listen.http".text}'";
      }
    ];
  };
}
