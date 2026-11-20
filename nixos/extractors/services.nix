{ config, lib, ... }:
let
  inherit (lib)
    attrByPath
    concatLists
    mapAttrsToList
    listToAttrs
    mkDefault
    mkEnableOption
    mkIf
    splitString
    ;

  inherit (config.topology) serviceRegistry;

  # A single service. `args` is passed to all registry functions.
  mkService =
    id: spec: args:
    let
      specNix = spec.nixos;
    in
    mkIf (specNix.enabled args) {
      serviceId = id;
      source = "nixos";

      # Undefined when the registry has no name, so the default falls back to the id
      name = mkIf (specNix.nameFn != null || spec.name != "") (
        mkDefault (if specNix.nameFn != null then specNix.nameFn args else spec.name)
      );
      icon = mkDefault (if specNix.iconFn != null then specNix.iconFn args else spec.icon);
      hidden = mkDefault spec.hidden;
      info =
        let
          val = specNix.infoFn args;
        in
        # Undefined when empty: info is types.lines, "" would add an empty line
        mkIf (val != null && val != "") val;
      details = specNix.detailsFn args;
    };

  # All services of a registry entry, as a list of name-value pairs: none without
  # a NixOS path, one per instance with `nixos.instances`, and one otherwise
  servicesFor =
    id: spec:
    let
      specNix = spec.nixos;
      # Empty if the option doesn't exist in this nixpkgs, which disables the service
      cfg = attrByPath (splitString "." specNix.path) { } config;
    in
    if specNix.path == null then
      [ ]
    else if specNix.instances then
      mapAttrsToList (instance: instanceCfg: {
        name = "${id}-${instance}";
        value = mkService id spec {
          inherit config instance;
          cfg = instanceCfg;
        };
      }) cfg
    else
      [
        {
          name = id;
          value = mkService id spec {
            inherit cfg config;
            instance = null;
          };
        }
      ];

  generated = listToAttrs (concatLists (mapAttrsToList servicesFor serviceRegistry));
in
{
  options.topology.extractors.services.enable = mkEnableOption "topology service extractor" // {
    default = true;
  };

  config.topology.self.services = mkIf config.topology.extractors.services.enable generated;
}
