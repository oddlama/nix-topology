{ lib }:
let
  inherit (lib) optionalString;
in
{
  name = "Nextcloud";
  icon = "services.nextcloud";
  nixos = {
    path = [
      "services"
      "nextcloud"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: "http${optionalString cfg.https "s"}://${cfg.hostName}";
    detailsFn = _: { };
  };
  test = {
    config = {
      services.nextcloud = {
        enable = true;
        hostName = "cloud.example.com";
        https = true;
        config.adminpassFile = "/dev/null";
      };
    };
    assertions = services: [
      {
        assertion = services.nextcloud.name == "Nextcloud";
        message = "expected name 'Nextcloud', got '${services.nextcloud.name}'";
      }
      {
        assertion = services.nextcloud.info == "https://cloud.example.com";
        message = "expected info 'https://cloud.example.com', got '${services.nextcloud.info}'";
      }
    ];
  };
}
