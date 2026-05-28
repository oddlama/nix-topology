{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Ollama";
  icon = "services.ollama";
  nixos = {
    path = [
      "services"
      "ollama"
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
      services.ollama = {
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        port = 11434;
      };
    };
    assertions = services: [
      {
        assertion = services.ollama.name == "Ollama";
        message = "expected name 'Ollama', got '${services.ollama.name}'";
      }
      {
        assertion = services.ollama.details.listen.text == "0.0.0.0:11434";
        message = "expected listen '0.0.0.0:11434', got '${services.ollama.details.listen.text}'";
      }
    ];
  };
}
