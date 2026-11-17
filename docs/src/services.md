# 🍵 Adding services

Services that are enabled on a NixOS host are detected automatically, as long as
nix-topology knows about them. All known services are defined in the service registry,
see `nixos/service-defs/` for the full list.

## Changing detected services

Detected services can be changed from the host's configuration under `topology.self.services.<id>`.
The id is the name of the registry entry, which is usually the name of the NixOS module (e.g. `grafana` for `services.grafana`).
Services with multiple instances, like restic backups, are called `<id>-<instance>`, for example `restic-backup-home`.

```nix
# ./host1/configuration.nix
{ lib, ... }: {
  topology.self.services.grafana = {
    name = "Dashboards";
    icon = ./dashboards.svg;
    # `info` and `details` are merged with what was detected,
    # use `lib.mkForce` to replace them instead.
    info = lib.mkForce "https://dashboards.example.com";
  };

  # Hide a service from the graphs
  topology.self.services.prometheus.hidden = true;
}
```

## Adding services to other nodes

Services on nodes that aren't NixOS hosts, such as routers or a NAS, can be added
manually. With `serviceId` they get the name and icon of a registry entry:

```nix
{
  nodes.router.services.dns = {
    serviceId = "adguardhome";
    info = "dns.example.com";
  };
}
```

## Adding your own services to the registry

You can define new registry entries, or change the existing ones, under `topology.serviceRegistry` in a NixOS configuration.
These entries apply to that host only, so if you want to use them on all hosts, put them in a module that all of them import.
The `serviceRegistry` in the global topology module only applies to nodes that aren't NixOS hosts.

```nix
# ./modules/topology-services.nix, imported by all hosts
{
  topology.serviceRegistry.my-app = {
    name = "My App";
    icon = ./my-app.svg;
    nixos = {
      # The service is shown if `services.my-app.enable` is true
      path = "services.my-app";
      infoFn = { cfg, ... }: "https://${cfg.domain}";
      detailsFn = { cfg, ... }: {
        listen.text = "${cfg.address}:${toString cfg.port}";
      };
    };
  };

  # Change a single field of an existing entry
  topology.serviceRegistry.grafana.name = "Dashboards";
}
```

The functions under `nixos` receive `cfg` (the value at `path`), `config` (the whole NixOS configuration)
and `instance`, and should accept further arguments with `...`. If the service has no `enable` option,
set `enabled` to a function that decides whether it's shown.
For services with multiple instances under one option, like `services.restic.backups`, set `instances = true`
to create one service per instance. The functions are then called with the instance's value as `cfg` and its name as `instance`.
See the [option reference](./topology-options.md) for all fields.
