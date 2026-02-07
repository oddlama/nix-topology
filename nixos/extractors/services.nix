{ config, lib, ... }:
let
  inherit (lib)
    attrByPath
    listToAttrs
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    ;

  inherit (config.topology) serviceRegistry;

  # Generate restic backup services dynamically
  resticBackupServices = mapAttrsToList (backupName: cfg: {
    name = "restic-backup-" + backupName;
    value = {
      serviceId = "restic-backup-" + backupName;
      source = "nixos";

      name = "Restic backup '${backupName}'";
      icon = "services.restic";

      info = mkIf (cfg.repository != null) cfg.repository;
      details = {
        paths = {
          text = toString cfg.paths;
        };
      };
    };
  }) (config.services.restic.backups or { });

  mkServiceFor =
    id: spec:
    let
      specNix = spec.nixos or null;
    in
    mkIf (specNix != null && specNix.path != [ ]) (
      let
        cfg = attrByPath specNix.path { } config;
        enabled = specNix.enabled cfg;
      in
      mkIf enabled {
        serviceId = id;
        source = "nixos";

        name = mkDefault spec.name;
        icon = mkDefault spec.icon;
        hidden = mkDefault (spec.hidden or false);
        info =
          let
            val = if specNix ? infoFn then specNix.infoFn cfg else null;
          in
          if val == null then "" else val;
        details = specNix.detailsFn cfg;
      }
    );

  generated = listToAttrs (
    (mapAttrsToList (id: spec: {
      name = id;
      value = mkServiceFor id spec;
    }) serviceRegistry)
    ++ resticBackupServices
  );
in
{
  options.topology.extractors.services.enable = mkEnableOption "topology service extractor" // {
    default = true;
  };

  config.topology.self.services = mkIf config.topology.extractors.services.enable generated;
}
