f: {
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    attrValues
    flatten
    flip
    mkDefault
    mkIf
    mkOption
    types
    ;
in
  f {
    options.nodes = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          services = mkOption {
            description = "Defines a service that is running on this node.";
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

                hidden = mkOption {
                  description = "Whether this service should be hidden from graphs";
                  default = false;
                  type = types.bool;
                };

                icon = mkOption {
                  description = "The icon for this service. Must be a path to an image or a valid icon name (<category>.<name>).";
                  type = types.nullOr (types.either types.path types.str);
                  default = null;
                };

                info = mkOption {
                  description = "Additional high-profile information about this service, usually the url or listen address. Most likely shown directly below the name.";
                  default = "";
                  type = types.lines;
                };

                details = mkOption {
                  description = "Additional detail sections that should be shown to the user.";
                  default = {};
                  type = types.attrsOf (types.submodule (detailSubmod: {
                    options = {
                      name = mkOption {
                        description = "The name of this section";
                        type = types.str;
                        readOnly = true;
                        default = detailSubmod.config._module.args.name;
                      };

                      order = mkOption {
                        description = "The order determines how sections are ordered. Lower numbers first, default is 100.";
                        type = types.int;
                        default = 100;
                      };

                      text = mkOption {
                        description = "The additional information to display";
                        type = types.lines;
                      };
                    };
                  }));
                };
              };

              config = {
                # Set the default icon, if an icon exists with a matching name
                icon = mkIf (config.topology.isMainModule && config.icons.services ? ${submod.config.id}) (
                  mkDefault ("services." + submod.config.id)
                );
              };
            }));
          };
        };
      });
    };

    config = {
      assertions = flatten (flip map (attrValues config.nodes) (
        node:
          flip map (attrValues node.services) (
            service: [
              (config.lib.assertions.iconValid
                service.icon "nodes.${node.id}.services.${service.id}")
            ]
          )
      ));
    };
  }
