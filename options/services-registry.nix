f:
{ lib, ... }:
let
  inherit (lib) mkOption types;
  # A function, stored as-is (not merged, so returned mkIf/mkMerge pass through untouched)
  fnType = types.addCheck types.raw builtins.isFunction // {
    description = "function";
  };

  fnArgsDoc = ''
    The function is called with an attribute set containing `cfg` (the value at `path`)
    and `config` (the whole NixOS configuration). Always accept further arguments
    with `...`, as more may be added in the future.
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
