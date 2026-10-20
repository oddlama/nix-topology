{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Coder";
  icon = "services.coder";
  nixos = {
    path = "services.coder";
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
    expect = {
      name = "Coder";
      info = "https://coder.example.com";
      details.listen = "0.0.0.0:3110";
    };
  };
}
