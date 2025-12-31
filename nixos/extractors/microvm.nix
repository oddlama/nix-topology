{ config, lib, ... }:
let
  inherit (lib)
    flip
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkVMOverride
    mod
    optionalAttrs
    optionals
    ;

  mapVms =
    f:
    flip mapAttrsToList config.microvm.vms (
      vmName: vm:
      f (if vm.flake != null then vm.flake.nixosConfigurations.${vmName}.config else vm.config.config)
    );
in
{
  options.topology.extractors.microvm.enable = mkEnableOption "topology microvm extractor" // {
    default = true;
  };

  config =
    mkIf
      (config.topology.extractors.microvm.enable && config ? microvm.host && config.microvm.host.enable)
      {
        topology.dependentConfigurations = mapVms (
          vmCfg: optionals (vmCfg ? topology) vmCfg.topology.definitions
        );
        topology.nodes = mkMerge (
          mapVms (
            vmCfg:
            optionalAttrs (vmCfg ? topology) {
              ${vmCfg.topology.id} = {
                guestType = "microvm";
                parent = config.topology.id;
                hardware.info =
                  let
                    ramGB10 = builtins.floor (10 * vmCfg.microvm.mem / 1024);
                    ramGB = if mod ramGB10 10 == 0 then ramGB10 / 10 else ramGB10 / 10.0;
                  in
                  mkVMOverride "microvm, ${toString ramGB}GB RAM";

                interfaces = mkMerge (
                  flip map vmCfg.microvm.interfaces (
                    i:
                    {
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
                    .${i.type} or {
                      ${i.id} = {
                        inherit (i) mac;
                        physicalConnections = [
                          {
                            node = config.topology.id;
                            interface = i.id;
                            renderer.reverse = true;
                          }
                        ];
                      };
                    }
                  )
                );
              };

              # Add interfaces to host
              ${config.topology.id} = {
                interfaces = mkMerge (
                  flip map vmCfg.microvm.interfaces (
                    i: { macvtap.${i.macvtap.link} = { }; }.${i.type} or { ${i.id} = { }; }
                  )
                );
              };
            }
          )
        );
      };
}
