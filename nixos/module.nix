{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    attrNames
    flip
    mkAliasOptionModule
    mkOption
    types
    ;
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

  config.topology = {
    # Ensure a node exists for this host
    nodes.${config.topology.id}.deviceType = "nixos";
  };
}
