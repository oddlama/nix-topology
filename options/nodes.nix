f: {
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    literalExpression
    mkOption
    types
    ;
in
  f {
    options.nodes = mkOption {
      default = {};
      description = ''
      '';
      type = types.attrsOf (types.submodule (nodeSubmod: {
        options = {
          id = mkOption {
            description = "The id of this node";
            default = nodeSubmod.config._module.args.name;
            readOnly = true;
            type = types.str;
          };

          name = mkOption {
            description = "The name of this node";
            type = types.str;
            default = nodeSubmod.config.id;
            defaultText = literalExpression ''"<name>"'';
          };

          # FIXME: TODO emoji / icon
          # FIXME: TODO hardware description "Odroid H3"
          # FIXME: TODO hardware image

          # FIXME: TODO are these good types? how about nixos vs router vs ...
          type = mkOption {
            description = "TODO";
            type = types.enum ["nixos" "microvm" "nixos-container"];
          };

          parent = mkOption {
            description = "The id of the parent node, if this node has a parent.";
            default = null;
            type = types.nullOr types.str;
          };
        };
      }));
    };
  }
