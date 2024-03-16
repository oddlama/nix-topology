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
          disks = mkOption {
            default = {};
            type = types.attrsOf (types.submodule (submod: {
              options = {
                id = mkOption {
                  description = "The id of this disk";
                  default = submod.config._module.args.name;
                  readOnly = true;
                  type = types.str;
                };
              };
            }));
          };
        };
      });
    };
  }
