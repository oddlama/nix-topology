{ lib }:
let
  inherit (lib) optionalString;
in
{
  name = "Nextcloud";
  icon = "services.nextcloud";
  nixos = {
    path = "services.nextcloud";
    infoFn = { cfg, ... }: "http${optionalString cfg.https "s"}://${cfg.hostName}";
  };
  oci.repos = [
    "nextcloud"
    "nextcloud/all-in-one"
  ];
  test = {
    minimalConfig = {
      services.nextcloud = {
        enable = true;
        hostName = "cloud.example.com";
      };
    };
    config = {
      services.nextcloud = {
        enable = true;
        hostName = "cloud.example.com";
        https = true;
        config.adminpassFile = "/dev/null";
      };
    };
    expect = {
      name = "Nextcloud";
      info = "https://cloud.example.com";
    };
  };
}
