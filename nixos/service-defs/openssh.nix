{ lib }:
let
  inherit (lib) concatStringsSep map;
in
{
  name = "OpenSSH";
  icon = "services.openssh";
  hidden = true;
  nixos = {
    path = [
      "services"
      "openssh"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.openssh.name == "OpenSSH";
        message = "expected name 'OpenSSH', got '${services.openssh.name}'";
      }
      {
        assertion = services.openssh.info == "port: 22, 2222";
        message = "expected info 'port: 22, 2222', got '${services.openssh.info}'";
      }
    ];
  };
}
