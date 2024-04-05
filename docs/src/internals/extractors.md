# Extractors

Each NixOS host automatically extracts information from its own configuration and exposes
it by defining services, interfaces or networks in its topology.
All extractors can be disabled individually, and you can define your own extractors if you want to.

The most prominent extractor is probably the services extractor, which adds service
icons and information for each known service that is enabled on a NixOS host.
Usually they just consist of one mkIf to show the service if it is enabled.
For example have a look at the vaultwarden service extractor, which is one of the more
complex ones (it's still quite simple):

```nix
vaultwarden = let
  domain = config.services.vaultwarden.config.domain or config.services.vaultwarden.config.DOMAIN or null;
  address = config.services.vaultwarden.config.rocketAddress or config.services.vaultwarden.config.ROCKET_ADDRESS or null;
  port = config.services.vaultwarden.config.rocketPort or config.services.vaultwarden.config.ROCKET_PORT or null;
in
  mkIf config.services.vaultwarden.enable {
    name = "Vaultwarden";
    icon = "services.vaultwarden";
    info = mkIf (domain != null) domain;
    details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
  };
```

If you want to add support for new services, feel free to create a PR. Contributions are wholeheartedly welcome!
There's more information in the [Development Chapter](./development.html).
