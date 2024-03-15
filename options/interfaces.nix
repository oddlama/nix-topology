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
          interfaces = mkOption {
            description = "TODO";
            default = {};
            type = types.attrsOf (types.submodule (submod: {
              options = {
                name = mkOption {
                  description = "The name of this interface";
                  type = types.str;
                  readOnly = true;
                  default = submod.config._module.args.name;
                };

                mac = mkOption {
                  description = "The MAC address of this interface, if known.";
                  default = null;
                  type = types.nullOr types.str;
                };

                addresses = mkOption {
                  description = "The configured address(es), or a descriptive string (like DHCP).";
                  type = types.listOf types.str;
                };

                network = mkOption {
                  description = ''
                    The global name of the attached/spanned network.
                    If this is given, this interface can be shown in the network graph.
                  '';
                  default = null;
                  type = types.nullOr types.str;
                };
              };
            }));
          };
        };
      });
    };
  }
