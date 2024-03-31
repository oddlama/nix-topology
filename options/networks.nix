f: {
  lib,
  config,
  options,
  ...
}: let
  inherit
    (lib)
    attrNames
    attrValues
    elemAt
    flatten
    flip
    foldl'
    imap0
    length
    mapAttrsToList
    mkOption
    mod
    optional
    optionalAttrs
    recursiveUpdate
    subtractLists
    types
    unique
    warnIf
    ;

  inherit
    (import ../topology/lazy.nix lib)
    isLazyValue
    lazyOf
    lazyValue
    ;

  style = primaryColor: secondaryColor: pattern: {
    inherit primaryColor secondaryColor pattern;
  };

  predefinedStyles = [
    (style "#f1cf8a" null "solid")
    (style "#70a5eb" null "solid")
    (style "#9dd68d" null "solid")
    (style "#5fe1ff" null "solid")
    (style "#e05f65" null "solid")
    (style "#f9a872" null "solid")
    (style "#78dba9" null "solid")
    (style "#9378de" null "solid")
    (style "#c68aee" null "solid")
    (style "#f5a6b8" null "solid")
    (style "#70a5eb" null "dashed")
    (style "#9dd68d" null "dashed")
    (style "#f1cf8a" null "dashed")
    (style "#5fe1ff" null "dashed")
    (style "#e05f65" null "dashed")
    (style "#f9a872" null "dashed")
    (style "#78dba9" null "dashed")
    (style "#9378de" null "dashed")
    (style "#c68aee" null "dashed")
    (style "#f5a6b8" null "dashed")
    (style "#e05f65" "#e3e6eb" "dashed")
    (style "#70a5eb" "#e3e6eb" "dashed")
    (style "#9378de" "#e3e6eb" "dashed")
    (style "#9dd68d" "#707379" "dashed")
    (style "#f1cf8a" "#707379" "dashed")
    (style "#5fe1ff" "#707379" "dashed")
    (style "#f9a872" "#707379" "dashed")
    (style "#78dba9" "#707379" "dashed")
    (style "#c68aee" "#707379" "dashed")
    (style "#f5a6b8" "#707379" "dashed")
  ];

  # A map containing all networks that have an explicitly assigned style, and the style.
  explicitStyles = foldl' recursiveUpdate {} (flatten (
    flip map options.networks.definitions (mapAttrsToList (
      netId: net:
        optional (net ? style && !isLazyValue net.style) {
          ${netId} = net.style;
        }
    ))
  ));

  # All unused predefined styles
  remainingStyles = subtractLists (unique (attrValues explicitStyles)) predefinedStyles;
  # All networks without styles
  remainingNets = subtractLists (attrNames explicitStyles) (attrNames config.networks);
  # Fold over all networks that have no style and assign the next free one. Warn and repeat from beginning if necessary.
  computedStyles =
    explicitStyles
    // warnIf
    (length remainingNets > length remainingStyles)
    "topology: There are more networks without styles than predefined styles. Some styles will have to be reused!"
    (
      foldl' recursiveUpdate {} (imap0 (i: net: {
          ${net} = elemAt remainingStyles (mod i (length remainingStyles));
        })
        remainingNets)
    );
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

          style =
            mkOption {
              description = ''
                A style for this network, usually used to draw connections.
                Must be an attrset consisting of three attributes:
                  - primaryColor (#rrggbb): The primary color, usually the color of edges.
                  - secondaryColor (#rrggbb): The secondary color, usually the background of a dashed line and only shown when pattern != solid. Set to null for transparent.
                  - pattern (solid, dashed, dotted): The pattern to use.
              '';
              type = lazyOf types.attrs;
            }
            // optionalAttrs config.topology.isMainModule {
              default = lazyValue computedStyles.${networkSubmod.config.id};
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
