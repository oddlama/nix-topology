{ config, lib, ... }:
let
  inherit (lib)
    concatMapStringsSep
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    types
    warnIf
    ;

  ociLib = import ../oci-lib.nix { inherit lib; };
  cfg = config.topology.extractors.oci-container;

  fnType = types.addCheck types.raw builtins.isFunction // {
    description = "function";
  };
  fnArgsDoc = ''
    The function is called with the same arguments as the `oci.*` functions of the service registry:
    `cfg` (the container's `virtualisation.oci-containers.containers.<name>`), `container` (the
    normalized container) and `config` (the whole NixOS configuration).
  '';

  ociContainers = config.virtualisation.oci-containers;
  containers = mapAttrsToList (
    name: c:
    ociLib.mkContainer {
      inherit name;
      inherit (ociContainers) backend;
      inherit (c)
        image
        ports
        labels
        environment
        volumes
        ;
      cfg = c;
    }
  ) ociContainers.containers;

  extracted = ociLib.mkServices {
    inherit containers config;
    inherit (cfg) infoFn detailsFn;
    registry = config.topology.serviceRegistry;
  };

  warning = ''
    topology: these OCI containers don't match any service in topology.serviceRegistry and are not shown:
    ${concatMapStringsSep "\n" (c: "  - ${c.name} (${c.image})") cfg.unmatched}
    To show a container, add its image to the `oci.repos` of a registry entry, for example
    `topology.serviceRegistry.<service>.oci.repos = [ "<image without tag>" ];`. A new entry needs
    a `name` and an `icon`, and `hidden = true` hides it. Set
    `topology.extractors.oci-container.warnUnmatched = false` to silence this warning.'';
in
{
  options.topology.extractors.oci-container = {
    enable = mkEnableOption "topology oci-container extractor" // {
      default = true;
    };

    warnUnmatched = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to warn about containers whose image doesn't match any registry entry.";
    };

    infoFn = mkOption {
      type = fnType;
      default = _: "";
      defaultText = lib.literalExpression ''_: ""'';
      description = "A function that returns the info of a container's service, used if the registry entry's `oci.infoFn` returns nothing. ${fnArgsDoc}";
    };

    detailsFn = mkOption {
      type = fnType;
      default = ociLib.defaultDetails;
      defaultText = lib.literalMD "the image without its digest and the published ports";
      description = "A function that returns the detail sections of a container's service. The registry entry's `oci.detailsFn` is merged over them. ${fnArgsDoc}";
    };

    unmatched = mkOption {
      type = types.listOf types.attrs;
      readOnly = true;
      internal = true;
      default = extracted.unmatched;
      description = "The containers whose image doesn't match any registry entry, as `{ name, image }`.";
    };
  };

  # The warning is part of the services, so it's only shown when the topology is evaluated
  config.topology.self.services = mkIf cfg.enable (
    warnIf (cfg.warnUnmatched && cfg.unmatched != [ ]) warning extracted.services
  );
}
