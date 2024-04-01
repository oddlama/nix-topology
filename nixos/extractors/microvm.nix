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
    mkVMOverride
    mod
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
            hardware.info = let
              ramGB10 = builtins.floor (10 * vm.config.config.microvm.mem / 1024);
              ramGB =
                if mod ramGB10 10 == 0
                then ramGB10 / 10
                else ramGB10 / 10.0;
            in
              mkVMOverride "microvm, ${toString ramGB}GB RAM";
          };
        }
    ));
  };
}
