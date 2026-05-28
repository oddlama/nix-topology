{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Coder";
  icon = "services.coder";
  nixos = {
    path = [
      "services"
      "coder"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        listenAddress = cfg.listenAddress or null;
      in
      mkIf (listenAddress != null) {
        listen = {
          text = listenAddress;
        };
      };
    infoFn = cfg: cfg.accessUrl;
  };
  test = {
    config = {
      services.coder = {
        enable = true;
        listenAddress = "0.0.0.0:3110";
        accessUrl = "https://coder.example.com";
      };
    };
    assertions = services: [
      {
        assertion = services.coder.name == "Coder";
        message = "expected name 'Coder', got '${services.coder.name}'";
      }
      {
        assertion = services.coder.info == "https://coder.example.com";
        message = "expected info 'https://coder.example.com', got '${services.coder.info}'";
      }
      {
        assertion = services.coder.details.listen.text == "0.0.0.0:3110";
        message = "expected listen '0.0.0.0:3110', got '${services.coder.details.listen.text}'";
      }
    ];
  };
}
