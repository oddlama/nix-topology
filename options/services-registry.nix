f:
{ lib, ... }:
let
  inherit (lib) lists mkOption types;
  serviceSubmodule =
    { name, ... }:
    {
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
                type = types.listOf types.str;
                default = [ ];
                description = "The NixOS options path for this service";
                apply = lists.unique;
              };
              enabled = mkOption {
                type = types.anything;
                description = "A function that determines if this service is enabled for a given NixOS configuration at the service's path";
              };
              nameFn = mkOption {
                type = types.anything;
                default = null;
                description = "An optional function that dynamically computes the service name from config. Takes precedence over the static `name` when set.";
              };
              infoFn = mkOption {
                type = types.anything;
                default = _: "";
                description = "A function that returns a string with additional high-profile information about this service, usually the url or listen address. Most likely shown directly below the name.";
              };
              detailsFn = mkOption {
                type = types.anything;
                default = _: { };
                description = "A function that returns additional detail sections that should be shown to the user";
              };
            };
          };
          default = { };
          description = "NixOS-specific metadata for this service";
        };
      };
    };
in
f {
  options.serviceRegistry = mkOption {
    description = "A registry of known services containing all metadata (name, icon, visibility flags) plus extractor-specific discovery, info, and details functions used by the graph renderers.";
    type = types.attrsOf (types.submodule serviceSubmodule);
    default = { };
  };

}
