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
                  description = "The icon for this service. Must be a valid entry in icons.services.";
                  type = types.nullOr types.str;
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
              {
                assertion = service.icon != null -> config.icons.services ? ${service.icon};
                message = "topology: nodes.${node.id}.services.${service.id} refers to an unknown icon icons.services.${service.icon}";
              }
            ]
          )
      ));
    };
  }
