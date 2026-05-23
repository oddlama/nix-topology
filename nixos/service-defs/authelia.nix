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
    path = "services.authelia";
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
    minimalConfig = {
      services.authelia.instances.main = {
        enable = true;
        secrets.jwtSecretFile = "/dev/null";
        secrets.storageEncryptionKeyFile = "/dev/null";
      };
    };
    config = {
      services.authelia.instances.main = {
        enable = true;
        secrets.jwtSecretFile = "/dev/null";
        secrets.storageEncryptionKeyFile = "/dev/null";
        settings.server.address = "tcp://0.0.0.0:9091/";
      };
    };
    expect = {
      name = "Authelia";
      details.main = "0.0.0.0:9091";
    };
  };
}
