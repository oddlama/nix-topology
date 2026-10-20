{ config, lib, ... }:
let
  inherit (lib)
    attrByPath
    listToAttrs
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    splitString
    ;

  inherit (config.topology) serviceRegistry;

  # Generate restic backup services dynamically
  resticBackupServices = mapAttrsToList (backupName: cfg: {
    name = "restic-backup-" + backupName;
    value = {
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
    mkIf (specNix != null && specNix.path != null) (
      let
        cfg = attrByPath (splitString "." specNix.path) { } config;
        enabled = specNix.enabled cfg;
      in
      mkIf enabled {
        serviceId = id;

        # Undefined when the registry has no name, so the default falls back to the id
        name = mkIf (specNix.nameFn != null || spec.name != "") (
          mkDefault (if specNix.nameFn != null then specNix.nameFn cfg else spec.name)
        );
        icon = mkDefault (if specNix.iconFn != null then specNix.iconFn cfg else spec.icon);
        hidden = mkDefault (spec.hidden or false);
        info =
          let
            val = if specNix ? infoFn then specNix.infoFn cfg else null;
          in
          # Undefined when empty: info is types.lines, "" would add an empty line
          mkIf (val != null && val != "") val;
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
