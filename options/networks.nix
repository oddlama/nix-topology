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
    options.networks = mkOption {
      default = {};
      description = "Defines logical networks that are present in your topology.";
      type = types.attrsOf (types.submodule (networkSubmod: {
        options = {
          id = mkOption {
            description = "The id of this network";
            default = networkSubmod.config._module.args.name;
            readOnly = true;
            type = types.str;
          };

          name = mkOption {
            description = "The name of this network";
            type = types.str;
            default = "Unnamed network '${networkSubmod.config.id}'";
          };

          icon = mkOption {
            description = "The icon representing this network. Must be a path to an image or a valid icon name (<category>.<name>).";
            type = types.nullOr (types.either types.path types.str);
            default = null;
          };

          color = mkOption {
            description = "The color of this network";
            default = "random";
            apply = x:
              if x == "random"
              then "#ff00ff" # FIXME: TODO: lookuptable linear probing hashing into palette
              else x;
            type = types.either (types.strMatching "^#[0-9a-f]{6}$") (types.enum ["random"]);
          };

          cidrv4 = mkOption {
            description = "The CIDRv4 address space of this network or null if it doesn't use ipv4";
            default = null;
            #type = types.nullOr types.net.cidrv4;
            type = types.nullOr types.str;
          };

          cidrv6 = mkOption {
            description = "The CIDRv6 address space of this network or null if it doesn't use ipv6";
            default = null;
            #type = types.nullOr types.net.cidrv6;
            type = types.nullOr types.str;
          };

          # FIXME: vlan ids
          # FIXME: nat to [other networks] (happening on node XY)
        };
      }));
    };

    config = {
      assertions = flatten (
        flip map (attrValues config.networks) (
          network: [
            (config.lib.assertions.iconValid
              network.icon "networks.${network.id}.icon")
          ]
        )
      );
    };
  }
