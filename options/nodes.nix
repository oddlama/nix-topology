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
in f {
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
          description = "TODO guests ids (topology.node.<name>.id) ensure exists";
          default = [];
          type = types.listOf types.str;
        };

        disks = mkOption {
          default = {};
          type = types.attrsOf (types.submodule (submod: {
            options = {
              name = mkOption {
                description = "The name of this disk";
                default = submod.config._module.args.name;
                readOnly = true;
                type = types.str;
              };
            };
          }));
        };

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

        firewallRules = mkOption {
          description = "TODO";
          default = {};
          type = types.attrsOf (types.submodule (submod: {
            options = {
              name = mkOption {
                description = "The name of this firewall rule";
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
    }));
  };

  config = {
    # TODO: assertions = []
  };
}
