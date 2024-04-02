{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    flip
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    types
    warnIf
    ;
in {
  options.topology.extractors.nixos-container.enable = mkEnableOption "topology nixos-container extractor" // {default = true;};

  options.containers = mkOption {
    type = types.attrsOf (types.submodule (submod: {
      options._nix_topology_config = mkOption {
        type = types.unspecified;
        internal = true;
        default =
          if submod.options.config.isDefined
          then submod.config.config
          else null;
        description = ''
          The configuration of the container. Defaults to `config` if that is used to define the container,
          otherwise must be set manually to make the topology extractor work.
        '';
      };
    }));
  };

  config = mkIf config.topology.extractors.nixos-container.enable {
    topology.nodes = mkMerge (flip mapAttrsToList config.containers (
      container: let
        containerCfg = warnIf (container._nix_topology_config == null) "topology: The nixos container ${container} uses `path` instead of `config`. Please set _nix_topology_config to the `.config` of its nixosSystem instanciation to allow nix-topology to access the configuration." container._nix_topology_config;
      in
        optionalAttrs (containerCfg != null && containerCfg ? topology) {
          ${container.config.topology.id} = {
            guestType = "nixos-container";
            parent = config.topology.id;
          };
        }
    ));
  };
}
