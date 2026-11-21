# Extractors

Each NixOS host automatically extracts information from its own configuration and exposes
it by defining services, interfaces or networks in its topology.
All extractors can be disabled individually, and you can define your own extractors if you want to.

The most prominent extractor is probably the services extractor, which adds service
icons and information for each known service that is enabled on a NixOS host.
The services it knows about are defined in the service registry, with one file per service in `nixos/service-defs/`.
Usually an entry just consists of a name, an icon and the NixOS option path of the service,
which is shown if its `enable` option is set. For example have a look at the vaultwarden entry,
which is one of the more complex ones (it's still quite simple):

```nix
{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Vaultwarden";
  icon = "services.vaultwarden";
  nixos = {
    path = "services.vaultwarden";
    infoFn =
      { cfg, ... }:
      let
        domain = cfg.config.domain or cfg.config.DOMAIN or null;
      in
      mkIf (domain != null) domain;
    detailsFn =
      { cfg, ... }:
      let
        address = cfg.config.rocketAddress or cfg.config.ROCKET_ADDRESS or null;
        port = cfg.config.rocketPort or cfg.config.ROCKET_PORT or null;
      in
      {
        listen = mkIf (address != null && port != null) { text = "${address}:${toString port}"; };
      };
  };
}
```

The oci-container extractor uses the same registry for the containers of `virtualisation.oci-containers`.
An entry lists the images of its service in `oci.repos`, and a container whose image matches becomes a service
with the id `oci-<container>`. Matching, parsing image references and building the services lives in `nixos/oci-lib.nix`,
which doesn't depend on the container backend, so an extractor for another backend only has to describe its containers.

The registry can also be extended from your own configuration, see [Adding Services](../services.md).

If you want to add support for new services, feel free to create a PR. Contributions are wholeheartedly welcome!
There's more information in the [Development Chapter](./development.html).
