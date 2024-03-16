f: {
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;
in
  f {
    options.nodes = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          services = mkOption {
            description = "TODO";
            default = {};
            type = types.attrsOf (types.submodule (submod: {
              options = {
                id = mkOption {
                  description = "The id of this service";
                  type = types.str;
                  readOnly = true;
                  default = submod.config._module.args.name;
                };

                name = mkOption {
                  description = "The name of this service";
                  type = types.str;
                };

                icon = mkOption {
                  description = "The icon for this service";
                  type = types.nullOr types.path;
                  default = null;
                };

                url = mkOption {
                  description = "The URL under which the service is reachable, if any.";
                  type = types.nullOr types.str;
                  default = null;
                };

                listenAddresses = mkOption {
                  description = "The addresses on which this service listens.";
                  type = types.nullOr types.str;
                  default = null;
                };
              };
            }));
          };
        };
      });
    };
  }
