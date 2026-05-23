{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Paperless-ngx";
  icon = "services.paperless-ngx";
  nixos = {
    path = [
      "services"
      "paperless"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn =
      cfg:
      let
        domain = cfg.domain or null;
      in
      mkIf (domain != null) "https://${domain}";
    detailsFn = cfg: {
      listen = {
        text = "${cfg.address}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.paperless = {
        enable = true;
        address = "0.0.0.0";
        port = 8000;
        domain = "paperless.example.com";
      };
    };
    assertions = services: [
      {
        assertion = services.paperless-ngx.name == "Paperless-ngx";
        message = "expected name 'Paperless-ngx', got '${services.paperless-ngx.name}'";
      }
      {
        assertion = services.paperless-ngx.info == "https://paperless.example.com";
        message = "expected info 'https://paperless.example.com', got '${services.paperless-ngx.info}'";
      }
      {
        assertion = services.paperless-ngx.details.listen.text == "0.0.0.0:8000";
        message = "expected listen '0.0.0.0:8000', got '${services.paperless-ngx.details.listen.text}'";
      }
    ];
  };
}
