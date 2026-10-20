{ config, lib, ... }:
let
  inherit (lib)
    concatStringsSep
    filter
    flip
    head
    isString
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    split
    ;

  inherit (config.virtualisation.oci-containers) backend containers;
in
{
  options.topology.extractors.oci-containers.enable =
    mkEnableOption "topology OCI container extractor"
    // {
      default = true;
    };

  config = mkIf (config.topology.extractors.oci-containers.enable && containers != { }) {
    topology.nodes = mkMerge (
      flip mapAttrsToList containers (
        containerName: container: {
          "${config.topology.id}-${backend}-${containerName}" = {
            guestType = backend;
            deviceType = "oci-container";
            deviceIcon = "devices.${backend}";
            services._guestInfo = {
              name = "Guest Information";
              hidden = true;
              details = {
                image.text = head (filter (v: isString v && v != "") (split "@|:" container.image));
                ports = mkIf (container.ports != [ ]) { text = concatStringsSep "\n" container.ports; };
                volumes = mkIf (container.volumes != [ ]) { text = concatStringsSep "\n" container.volumes; };
              };
            };
            parent = config.topology.id;
          };
        }
      )
    );
  };
}
