{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Tor";
  icon = "services.tor";
  nixos = {
    path = [
      "services"
      "tor"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: mkIf (cfg.relay.enable or false) "Role: ${cfg.relay.role}";
    detailsFn = _: { };
  };
  test = {
    config = {
      services.tor = {
        enable = true;
        relay = {
          enable = true;
          role = "relay";
        };
      };
    };
    assertions = services: [
      {
        assertion = services.tor.name == "Tor";
        message = "expected name 'Tor', got '${services.tor.name}'";
      }
      {
        assertion = services.tor.info == "Role: relay";
        message = "expected info 'Role: relay', got '${services.tor.info}'";
      }
    ];
  };
}
