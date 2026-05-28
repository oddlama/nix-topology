{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Atuin";
  icon = "services.atuin";
  nixos = {
    path = [
      "services"
      "atuin"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.host}:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.atuin = {
        enable = true;
        openFirewall = true;
        host = "127.0.0.1";
        port = 8888;
      };
    };
    assertions = services: [
      {
        assertion = services.atuin.name == "Atuin";
        message = "expected name 'Atuin', got '${services.atuin.name}'";
      }
      {
        assertion = services.atuin.details.listen.text == "127.0.0.1:8888";
        message = "expected listen '127.0.0.1:8888', got '${services.atuin.details.listen.text}'";
      }
    ];
  };
}
