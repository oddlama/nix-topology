# Development

First of all, here's a very quick overview over the codebase:

- `examples/` each folder in here should contain a `flake.nix` as a user would write it for their configuration.
  Each such example flake will automatically be evaluated and rendered in the documentation.
- `icons/` contains all the service, device and interface icons. Placing a new file here will automatically register it.
- `nixos/` contains anything related to the provided NixOS module. Mostly information extractors,
  and the service registry in `nixos/service-defs/` with one file per known service.
- `options/` contains shared options. Shared means that all of these options will be present
  both in the global topology module and also in each NixOS module under the `topology` option,
  which will be merged into the global topology. If you need NixOS specific options (like extractors) or topology specific options (like renderers)
  have a look at `nixos/module.nix` and `topology/default.nix`.
- `pkgs/` contains our nixpkgs overlay and packages required to render the graphs.
- `topology/` contains anything related to the global topology module. This is where the NixOS configurations
  are merged into the global topology and where the renderers are defined.

## Criteria for new extractors and service extractors

I'm generally happy to accept any extractor, but please make sure they meet the following criteria:

- It must provide an `enable` option so it can be disabled. It may be enabled by default, if it is a no-op
  for systems that don't use the relevant parts. The services extractor for example only adds services
  whose `enable` option is set, and skips services whose options don't exist in the host's nixpkgs.
- The default settings of an extractor (or any part of it) should try not to cause clutter in the generated cards.
  Take for example OpenSSH which is usually enabled on all machines. Showing it by default would cause a lot of unnecessary clutter,
  so it should be guarded behind an additional option that is disabled by default. Same goes for common local services like smartd, fwupd, ...
- Extractors should be made for things available in nixpkgs or the broader list of community projects.
  So I'm happy to accept extractors for projects like (microvm.nix, disko, ...) but if you want to extract
  information from very niche or personal projects, it might be better to include the extractor in there.

  If you write an extractor for such a third party dependency, make sure that it is either disabled by default,
  or guarded in a way so that it doesn't affect vanilla systems. Check the microvm extractor for an example which
  makes sure that the microvm module is acutually used on the target system.

## Adding a new extractor

To add a whole new extractor, all you need to do is to create `nixos/extractors/foo.nix`,
and add a new option for your extractor:

```nix
{ config, lib, ... }: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.topology.extractors.foo.enable = mkEnableOption "topology foo extractor" // {default = true;};
  config = mkIf (config.topology.extractors.foo.enable && /* additional checks if necessary */) {
    topology = {
      # Modify topology based on the information you gathered
    };
  };
}
```

The file will automatically be included by the main NixOS module.

## Adding a service to the services extractor

To add a new service, all you need to do is to create a new file `nixos/service-defs/<service_name>.nix`.
It will be picked up automatically, and the file name is the id of the service.

Imagine we want to add support for vaultwarden, we would start by extracting some information,
while making sure there's a sensible fallback value at all times if the value isn't set.
Don't depend on any value being set, only observe what the user has actually configured!

```nix
{ lib }:
let
  inherit (lib) mkIf;
in
{
  # The service's proper name.
  name = "Vaultwarden";
  # An icon from the icon registry. We will add a new icon for the service later.
  icon = "services.vaultwarden";
  nixos = {
    # The NixOS option path of the service. It's shown if `<path>.enable` is set,
    # use `enabled = { cfg, config, ... }: ...;` if you need a different condition.
    # All functions receive the value at `path` as `cfg` and the whole configuration as `config`.
    path = "services.vaultwarden";
    # One line of information that should be shown below the service name.
    # Usually this should be the hosted domain name (if it is known), or very very important information.
    # For vaultwarden, we use the domain from the config. If you are unsure for your service, just leave
    # it out so users can set it manually via topology.self.services.<service>.info = "...";
    infoFn =
      { cfg, ... }:
      let
        domain = cfg.config.domain or cfg.config.DOMAIN or null;
      in
      mkIf (domain != null) domain;
    # In details you can add more information specific to the service.
    # Currently I tried to include a `listen` detail for any service listening on an address/port.
    # Samba for example shows the configured shares and nginx the configured reverse proxies.
    # If you are unsure what to do here, just leave it out.
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
  # Every service is tested by evaluating a NixOS configuration with nixpkgs unstable and stable.
  test = {
    # The configuration to test with, `<path>.enable = true;` if not set.
    config = {
      services.vaultwarden = {
        enable = true;
        config = {
          domain = "https://vault.example.com";
          rocketAddress = "0.0.0.0";
          rocketPort = 8222;
        };
      };
    };
    # The expected fields of the service with `test.config`, `details.<name>` is the text of that detail.
    expect = {
      name = "Vaultwarden";
      info = "https://vault.example.com";
      details.listen = "0.0.0.0:8222";
    };
    # Optional: the service must also appear when enabled with only the settings NixOS requires.
    # Set this if `<path>.enable = true;` alone isn't enough. Defaults to `<path>.enable = true;`.
    # minimalConfig = { ... };
    # Optional: additional assertions, given all extracted services of `test.config`.
    # assertions = services: [ { assertion = ...; message = "..."; } ];
  };
}
```

If the service is also distributed as a container image, add the image's repositories to `oci.repos`.
Use the shortest pattern that identifies the service: a pattern matches the last path components of an image,
so `jellyfin` matches `jellyfin/jellyfin` mirrored anywhere, as well as rebuilds like `lscr.io/linuxserver/jellyfin`.
Bare names are only for distinctive project names (`jellyfin`, `paperless-ngx`, `immich-server`). If the last component is
generic, qualify it with its namespace (`vaultwarden/server`, `kanidm/server`, `mautrix/signal`), and never include a registry.
The `oci.nameFn`, `oci.iconFn`, `oci.infoFn` and `oci.detailsFn` functions work like the `nixos` ones,
but get the container as `container` and its options as `cfg`:

```nix
  oci.repos = [
    "vaultwarden"
    "vaultwarden/server"
  ];
```

The tests check that each pattern, used as an image, resolves to this entry and no other.
To test the `oci` functions, add the containers and the expected fields of their services by container name:

```nix
  test.oci = {
    containers.db.image = "mariadb:11";
    expect.db = {
      name = "MariaDB";
      icon = "services.mariadb";
    };
  };
```

If a service can have multiple instances under one option (like `services.restic.backups`), set `nixos.instances = true;`.
Then one service is created per instance with the id `<service_name>-<instance>`, the functions get the instance's value
as `cfg` and its name as `instance`, and the test needs `test.instance` to select the instance to check.

You can run the test of your service with `nix build .#checks.x86_64-linux.service-def-<service_name>`,
and on nixpkgs stable with `nix build .#checks.x86_64-linux.service-def-<service_name>-stable`.

Now we still need to add an icon to the registry, but then the service is finished.
nix-topology supports svg, png and jpeg files, but we prefer SVG wherever possible.
Usually you should be able to find the original logo of any project in their main repository
on GitHub by searching for `.svg` by pressing <kbd>t</kbd>.

But before we put it in `icons/services/<service_name>.svg`, we should optimize the svg
and make sure it has a square `viewBox="..."` property set. For this I recommend passing it through
`scour` and `svgo` once, this will do all of the work automatically, except for making sure that the
logo is square:

```bash
nix-shell -p nodePackages.svgo scour
scour --enable-viewboxing -i original.svg -o tmp.svg
svgo -i tmp.svg -o service_name.svg
```

If you open the file and see a viewBox like `viewBox="0 0 100 100"`, then you are ready to go.
The actual numbers don't matter, but the last two (width and height) should be the same. If they
are not, open the file in any svg editor of your liking, for example Inkscape or [boxy-svg.com](https://boxy-svg.com/)
and make it square manually. (In theory you can also just increase the smaller number and `x` or `y` by half of that
in the viewBox by hand. Run it through `svgo` another time and you are all set.

## Adding an example

Examples are currently our tests. They are automatically built together with the documentation
and the rendered result is also included in the docs. If you have made a complex extractor,
you might want to test it by creating a new example.

All you need to do for that to happen is to create a `flake.nix` in a new example folder,
for example `examples/foo/flake.nix`. Just copy the simple example and start from there.
The flake should be a regular flake containing `nixosConfigurations`, just like what a user would
write. Beware that you currently cannot add inputs to that flake, let me know if you need that.

To build the example, just build the documentation:

```bash
nix build .#docs`
```
