{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Ollama";
  icon = "services.ollama";
  nixos = {
    path = "services.ollama";
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
      services.ollama = {
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        port = 11434;
      };
    };
    expect = {
      name = "Ollama";
      details.listen = "0.0.0.0:11434";
    };
  };
}
