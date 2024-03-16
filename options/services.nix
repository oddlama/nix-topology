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

                icon = mkOption {
                  description = "The icon for this service";
                  type = types.nullOr types.path;
                  default = null;
                };

                info = mkOption {
                  description = "Additional high-profile information about this service, usually the url or listen address. Most likely shown directly below the name.";
                  type = types.lines;
                };

                details = mkOption {
                  description = "Additional detail sections that should be shown to the user.";
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
  }
