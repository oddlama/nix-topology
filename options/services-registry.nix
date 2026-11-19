f:
{ lib, ... }:
let
  inherit (lib) mkOption types;
  # A function, stored as-is (not merged, so returned mkIf/mkMerge pass through untouched)
  fnType = types.addCheck types.raw builtins.isFunction // {
    description = "function";
  };

  fnArgsDoc = ''
    The function is called with an attribute set containing `cfg` (the value at `path`,
    or the instance's value if `instances` is set), `instance` (the name of the instance,
    or null) and `config` (the whole NixOS configuration). Always accept further arguments
    with `...`, as more may be added in the future.
  '';
  ociFnArgsDoc = ''
    The function is called with an attribute set containing `cfg` (the container's raw
    backend configuration, such as `virtualisation.oci-containers.containers.<name>`),
    `container` (a normalized description of the container, the same for all backends:
    `{ name, backend, image = { reference, registry, repository, tag, digest }, ports,
    labels, environment, volumes }`) and `config` (the whole NixOS configuration).
    Always accept further arguments with `...`, as more may be added in the future.
  '';
  serviceSubmodule = { name, ... }: {
    options = {
      serviceId = mkOption {
        type = types.str;
        default = name;
        description = "The unique identifier for this service. Defaults to the attribute name.";
      };

      name = mkOption {
        type = types.str;
        description = "The name of this service";
        default = "";
      };

      icon = mkOption {
        type = types.nullOr (types.either types.path types.str);
        description = "The icon for this service. Must be a path to an image or a valid icon name (<category>.<name>).";
        default = null;
      };

      hidden = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this service should be hidden from graphs";
      };

      nixos = mkOption {
        type = types.submodule {
          options = {
            path = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "services.grafana";
              description = "The NixOS option path for this service. Services whose path doesn't exist in a host's nixpkgs are skipped.";
            };
            instances = mkOption {
              type = types.bool;
              default = false;
              example = true;
              description = ''
                Whether the value at `path` is an attribute set of instances, such as
                `services.restic.backups`. If set, one service is created for each instance
                with the id `<service-id>-<instance>`, and the functions below are called for
                each instance.
              '';
            };
            enabled = mkOption {
              type = fnType;
              default = { cfg, ... }: cfg.enable or false;
              defaultText = lib.literalExpression "{ cfg, ... }: cfg.enable or false";
              description = "A function that determines if this service is enabled. ${fnArgsDoc}";
            };
            nameFn = mkOption {
              type = types.nullOr fnType;
              default = null;
              description = "An optional function that dynamically computes the service name. Takes precedence over the static `name` when set. ${fnArgsDoc}";
            };
            iconFn = mkOption {
              type = types.nullOr fnType;
              default = null;
              description = "An optional function that dynamically computes the service icon. Takes precedence over the static `icon` when set. ${fnArgsDoc}";
            };
            infoFn = mkOption {
              type = fnType;
              default = _: "";
              defaultText = lib.literalExpression ''_: ""'';
              description = "A function that returns a string with additional high-profile information about this service, usually the url or listen address. Most likely shown directly below the name. ${fnArgsDoc}";
            };
            detailsFn = mkOption {
              type = fnType;
              default = _: { };
              defaultText = lib.literalExpression "_: { }";
              description = "A function that returns additional detail sections that should be shown to the user. ${fnArgsDoc}";
            };
          };
        };
        default = { };
        description = "NixOS-specific metadata for this service";
      };

      oci = mkOption {
        type = types.submodule {
          options = {
            repos = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [
                "jellyfin"
                "registry.lan/mirror/jellyfin"
              ];
              description = ''
                Image repositories of this service. A container whose image matches one of them
                becomes a service of this entry. A pattern matches when its path components equal
                the trailing components of the image's repository, so `jellyfin` matches
                `jellyfin/jellyfin`, `lscr.io/linuxserver/jellyfin` and
                `registry.lan/proxy/jellyfin/jellyfin`, but not `jellyfin-vue`. Tags, digests and the
                registry are ignored, unless the pattern starts with a registry (a first component with a
                `.` or `:`, or `localhost`), which then has to match too. If several entries match, the
                most specific pattern wins: one with a registry, then the one with more components.

                Lists from several definitions are concatenated, so you can add repositories to a built-in
                entry. Use `lib.mkForce` to replace them.
              '';
            };
            nameFn = mkOption {
              type = types.nullOr fnType;
              default = null;
              description = "An optional function that dynamically computes the service name. Takes precedence over the static `name` when set. ${ociFnArgsDoc}";
            };
            iconFn = mkOption {
              type = types.nullOr fnType;
              default = null;
              description = "An optional function that dynamically computes the service icon. Takes precedence over the static `icon` when set. ${ociFnArgsDoc}";
            };
            infoFn = mkOption {
              type = fnType;
              default = _: "";
              defaultText = lib.literalExpression ''_: ""'';
              description = "A function that returns a string with additional high-profile information about this service. Takes precedence over the extractor's `infoFn` when it returns a non-empty string. ${ociFnArgsDoc}";
            };
            detailsFn = mkOption {
              type = fnType;
              default = _: { };
              defaultText = lib.literalExpression "_: { }";
              description = "A function that returns additional detail sections, merged over the extractor's details. ${ociFnArgsDoc}";
            };
          };
        };
        default = { };
        description = "Metadata for OCI containers of this service, used by the oci-container extractor";
      };
    };
  };
in
f {
  options.serviceRegistry = mkOption {
    description = ''
      A registry of known services containing all metadata (name, icon, visibility flags)
      plus extractor-specific discovery, info, and details functions used by the graph renderers.
      Services refer to an entry with `serviceId`, and the services extractor adds a service
      for each entry whose `nixos` settings match a NixOS host's configuration.

      Each NixOS host has its own registry under `topology.serviceRegistry`, which applies to the
      services of that host. The registry in the global topology module only applies to
      nodes that aren't NixOS hosts, such as routers. To change an entry for all NixOS hosts,
      define it in a NixOS module that all of them import.
    '';
    type = types.attrsOf (types.submodule serviceSubmodule);
    default = { };
  };

}
