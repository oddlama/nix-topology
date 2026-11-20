{ lib }:
let
  inherit (lib) mapAttrs;
in
{
  name = "OpenBao";
  icon = "services.openbao";
  nixos = {
    path = "services.openbao";
    infoFn = { cfg, ... }: cfg.settings.api_addr or null;
    detailsFn =
      { cfg, ... }: mapAttrs (_: listener: { text = listener.address; }) (cfg.settings.listener or { });
  };
  test = {
    config = {
      services.openbao = {
        enable = true;
        settings = {
          api_addr = "https://bao.example.com";
          listener = {
            default = {
              type = "tcp";
              address = "127.0.0.1:8200";
            };
            socket = {
              type = "unix";
              address = "/run/openbao/openbao.sock";
            };
          };
        };
      };
    };
    expect = {
      name = "OpenBao";
      info = "https://bao.example.com";
      details = {
        default = "127.0.0.1:8200";
        socket = "/run/openbao/openbao.sock";
      };
    };
  };
}
