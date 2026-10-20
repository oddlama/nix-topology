{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Atuin";
  icon = "services.atuin";
  nixos = {
    path = "services.atuin";
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
    expect = {
      name = "Atuin";
      details.listen = "127.0.0.1:8888";
    };
  };
}
