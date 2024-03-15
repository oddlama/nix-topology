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
      default = {};
      description = ''
      '';
      type = types.attrsOf (types.submodule (nodeSubmod: {
        options = {
          name = mkOption {
            description = "The name of this node";
            default = nodeSubmod.config._module.args.name;
            readOnly = true;
            type = types.str;
          };

          type = mkOption {
            description = "TODO";
            default = "normal";
            type = types.enum ["normal" "microvm" "nixos-container"];
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
