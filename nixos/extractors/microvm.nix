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
      vm: let
        vmCfg = vm.config.config;
      in
        optionalAttrs (vmCfg ? topology) {
          ${vmCfg.topology.id} = {
            guestType = "microvm";
            parent = config.topology.id;
            hardware.info = let
              ramGB10 = builtins.floor (10 * vmCfg.microvm.mem / 1024);
              ramGB =
                if mod ramGB10 10 == 0
                then ramGB10 / 10
                else ramGB10 / 10.0;
            in
              mkVMOverride "microvm, ${toString ramGB}GB RAM";

            interfaces = mkMerge (flip map vmCfg.microvm.interfaces (
              i:
                {
                  tap.${i.id} = {
                    inherit (i) mac;
                    physicalConnections = [
                      {
                        node = config.topology.id;
                        interface = i.id;
                        renderer.reverse = true;
                      }
                    ];
                  };
                  macvtap.${i.macvtap.link} = {
                    inherit (i) mac;
                    physicalConnections = [
                      {
                        node = config.topology.id;
                        interface = i.macvtap.link;
                        renderer.reverse = true;
                      }
                    ];
                  };
                }
                .${i.type}
                or {}
            ));
          };
        }
    ));
  };
}
