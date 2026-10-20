{ lib }:
let
  inherit (lib) concatStringsSep map;
in
{
  name = "OpenSSH";
  icon = "services.openssh";
  hidden = true;
  nixos = {
    path = "services.openssh";
    infoFn = cfg: "port: ${concatStringsSep ", " (map toString cfg.ports)}";
    detailsFn = _: { };
  };
  test = {
    config = {
      services.openssh = {
        enable = true;
        ports = [
          22
          2222
        ];
      };
    };
    expect = {
      name = "OpenSSH";
      info = "port: 22, 2222";
    };
  };
}
