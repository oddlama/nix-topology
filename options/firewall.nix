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
          firewallRules = mkOption {
            description = "TODO";
            default = {};
            type = types.attrsOf (types.submodule (submod: {
              options = {
                id = mkOption {
                  description = "The id of this firewall rule";
                  type = types.str;
                  readOnly = true;
                  default = submod.config._module.args.name;
                };

                contents = mkOption {
                  description = "A human readable summary of this rule's effects";
                  type = types.lines;
                };
              };
            }));
          };
        };
      });
    };
  }
