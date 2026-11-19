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

## Containers

Containers of `virtualisation.oci-containers` (docker or podman) are shown as services if the registry knows
their image. Each container becomes a service with the id `oci-<container>`, which you can change under
`topology.self.services.oci-<container>` like any other service. By default it shows the image and the published ports.
Its `source` is `oci`, and `nixos` for the services of NixOS modules, so a custom renderer can tell them apart.

A registry entry lists its images in `oci.repos`. A pattern matches when its path components equal the last components
of the image's repository, ignoring the registry, tag and digest. So `jellyfin` matches `jellyfin/jellyfin`,
`lscr.io/linuxserver/jellyfin:10.10.7`, `ghcr.io/hotio/jellyfin` and `harbor.example.com/proxy/jellyfin/jellyfin`,
but not `jellyfin-vue`. A pattern that starts with a registry, such as `registry.example.com/jellyfin`, also needs the registry to match.
If several entries match, the most specific pattern wins: one with a registry, then the one with more components.

Containers whose image doesn't match any entry are skipped, with a warning when the topology is built.
To show such a container, add its image to an entry:

```nix
# ./host1/configuration.nix
{ lib, ... }: {
  # An image the registry doesn't know yet, such as a mirror under a different name.
  # This is added to the built-in list, use `lib.mkForce` to replace it.
  topology.serviceRegistry.paperless-ngx.oci.repos = [ "registry.example.com/mirror/paperless" ];

  # A new entry
  topology.serviceRegistry.uptime-kuma = {
    name = "Uptime Kuma";
    icon = ./uptime-kuma.svg;
    oci = {
      repos = [ "uptime-kuma" ];
      infoFn = { container, ... }: "https://status.example.com";
    };
  };

  # Sidecars you don't want to see: a hidden entry hides them and silences the warning
  topology.serviceRegistry.redis = {
    hidden = true;
    oci.repos = [ "redis" "valkey" ];
  };

  # Or skip unknown containers silently
  topology.extractors.oci-container.warnUnmatched = false;
}
```

The functions under `oci` receive `cfg` (the container's options), `config` (the whole NixOS configuration) and `container`,
the container in a form that is the same for all container backends:
`{ name, backend, image = { reference, registry, repository, tag, digest }, ports, labels, environment, volumes }`.
Docker Hub images are normalized, so `nginx` and `docker.io/library/nginx` both have the registry `docker.io` and the repository `nginx`.
`topology.extractors.oci-container.infoFn` and `detailsFn` take the same arguments and apply to all containers.
An entry's `oci.infoFn` wins over the extractor's if it returns something, and its `oci.detailsFn` is merged over the extractor's details.
If several services on a host have the same name, the container's name is appended, for example `PostgreSQL (immich-db)`.

See the [oci-containers example](./examples/oci-containers/main.md) for a complete configuration.
