{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    attrValues
    flip
    mkEnableOption
    mkIf
    mkMerge
    optionalAttrs
    ;
in {
  options.topology.extractors.microvm.enable = mkEnableOption "topology microvm extractor" // {default = true;};

  config = mkIf (config.topology.extractors.microvm.enable && config ? microvm && config.microvm.host.enable) {
    topology.nodes = mkMerge (flip map (attrValues config.microvm.vms) (
      vm:
        optionalAttrs (vm.config.config ? topology) {
          ${vm.config.config.topology.id} = {
            guestType = "microvm";
            parent = config.topology.id;
          };
        }
    ));
  };
}
