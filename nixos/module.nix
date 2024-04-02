{
  config,
  lib,
  options,
  ...
}: let
  inherit
    (lib)
    attrNames
    flatten
    flip
    genAttrs
    mkAliasOptionModule
    mkMerge
    mkOption
    optional
    types
    ;

  toplevelRelevantOptions = ["nodes" "networks"];
in {
  imports =
    [
      # Allow simple alias to set/get attributes of this node
      (mkAliasOptionModule ["topology" "self"] ["topology" "nodes" config.topology.id])
    ]
    # Include extractors
    ++ map (x: ./extractors/${x}) (attrNames (builtins.readDir ./extractors))
    # Include common topology options
    ++ flip map (attrNames (builtins.readDir ../options)) (x:
      import ../options/${x} (
        module:
          module
          // {
            # Move options to subpath
            options.topology = module.options or {};
            # Set the correct filename for diagnostics
            _file = ../options/${x};
            # The config should only be applied on the toplevel topology module,
            # not for each nixos node.
            config = {};
          }
      ));

  options.topology = {
    definitions = genAttrs toplevelRelevantOptions (opt:
      mkOption {
        internal = true;
        readOnly = true;
        description = ''
          Exposes options.${opt}.definitions as a config option. This is necessary
          so we can access the raw definitions of e.g. nixos-containers which
          only make `.config` accessible to the outside and not `.options`.
        '';
        default = options.topology.${opt}.definitions;
        type = types.unspecified;
      });

    dependentConfigurations = mkOption {
      internal = true;
      description = ''
        A list of option definition values that shall be merged with this host's definitions.
        Useful to bring in dependent configurations like nixos-containers or vm configs.
      '';
      type = types.listOf types.unspecified;
    };

    id = mkOption {
      description = ''
        The attribute name in the given `nodes` which corresponds to this host.
        Please overwrite it with a unique identifier if your hostnames are not
        unique or don't reflect the name you use to refer to that node.
      '';
      default = config.networking.hostName;
      type = types.str;
    };

    isMainModule = mkOption {
      description = "Whether this is the toplevel topology module.";
      readOnly = true;
      internal = true;
      default = false;
      type = types.bool;
    };
  };

  config = mkMerge (
    [
      {
        # Ensure a node exists for this host
        topology.nodes.${config.topology.id}.deviceType = "nixos";
      }
    ]
    ++ flip map toplevelRelevantOptions (
      opt: {
        topology.${opt} = mkMerge (flatten (
          flip map config.topology.dependentConfigurations (
            cfg:
              optional (cfg ? ${opt}) cfg.${opt}
          )
        ));
      }
    )
  );
}
