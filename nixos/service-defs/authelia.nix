{ lib }:
let
  inherit (lib)
    filterAttrs
    listToAttrs
    mapAttrsToList
    removeSuffix
    removePrefix
    ;
in
{
  name = "Authelia";
  icon = "services.authelia";
  nixos = {
    path = [
      "services"
      "authelia"
    ];
    enabled = cfg: (filterAttrs (_: v: v.enable) (cfg.instances or { })) != { };
    detailsFn =
      cfg:
      let
        instances = filterAttrs (_: v: v.enable) cfg.instances;
      in
      listToAttrs (
        mapAttrsToList (name: v: {
          inherit name;
          value = {
            text = removeSuffix "/" (removePrefix "tcp://" v.settings.server.address);
          };
        }) instances
      );
  };
  test = {
    config = {
      services.authelia.instances.main = {
        enable = true;
        secrets.jwtSecretFile = "/dev/null";
        secrets.storageEncryptionKeyFile = "/dev/null";
        settings.server.address = "tcp://0.0.0.0:9091/";
      };
    };
    assertions = services: [
      {
        assertion = services.authelia.name == "Authelia";
        message = "expected name 'Authelia', got '${services.authelia.name}'";
      }
      {
        assertion = services.authelia.details.main.text == "0.0.0.0:9091";
        message = "expected detail main '0.0.0.0:9091', got '${services.authelia.details.main.text}'";
      }
    ];
  };
}
