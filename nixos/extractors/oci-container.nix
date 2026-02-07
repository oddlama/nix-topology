{ config, lib, ... }:
let
  inherit (lib)
    attrNames
    attrValues
    concatStringsSep
    filter
    flatten
    head
    hasSuffix
    length
    listToAttrs
    mapAttrs
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    seq
    strings
    tail
    types
    ;

  inherit (config.topology) serviceRegistry;

  containers = mapAttrsToList (
    name: cfg: cfg // { _name = name; }
  ) config.virtualisation.oci-containers.containers;

  # Remove both registry AND tag/digest
  canonical =
    img:
    let
      noTag = head (strings.splitString ":" img);
      noDigest = head (strings.splitString "@" noTag);
      parts = strings.splitString "/" (strings.toLower noDigest);

      # If there are three or more components,
      # the leftmost one is the registry. If there are only
      # two, the first might be a registry or a namespace
      # (e.g. "library/nginx").
      repoParts = if (length parts) > 2 then tail parts else parts;
    in
    concatStringsSep "/" repoParts;
  suffixMatch =
    img: repo:
    let
      canon = canonical img;
      repoLower = strings.toLower repo;
    in
    canon == repoLower || strings.hasSuffix ("/" + repoLower) canon;
  matchesRepos = img: repos: builtins.any (suffixMatch img) repos;

  matchesById = mapAttrs (
    _: spec:
    let
      oci = spec.oci or null;
    in
    if oci == null then [ ] else filter (c: matchesRepos c.image oci.repos) containers
  ) serviceRegistry;

  mkServiceFromHits =
    id: spec: hits:
    mkIf (hits != [ ]) (
      let
        firstHit = head hits;
        defaultInfoFn = config.topology.extractors.oci-container.infoFn;
        serviceInfoFn = spec.oci.infoFn or null;
        infoVal = (if serviceInfoFn != null then serviceInfoFn else defaultInfoFn) firstHit;
        defaultDetailsFn = config.topology.extractors.oci-container.detailsFn;
        serviceDetailsFn = spec.oci.detailsFn or (_: { });
        detailsVal = (defaultDetailsFn firstHit) // (serviceDetailsFn firstHit);
      in
      {
        serviceId = id;
        source = "oci";
        name = mkDefault spec.name;
        info = mkDefault infoVal;
        details = mkDefault detailsVal;
        hidden = mkDefault (spec.hidden or false);
      }
      // optionalAttrs (spec ? icon) { icon = mkDefault spec.icon; }
    );

  traefikHostInfoFn =
    cfg:
    let
      labels = cfg.labels or { };
      ruleKeys = filter (k: hasSuffix ".rule" k && strings.hasPrefix "traefik.http.routers." k) (
        attrNames labels
      );
      hosts = concatStringsSep " " (
        map (
          k:
          let
            m = builtins.match "Host\\(`([^`]*)`\\)" labels.${k};
          in
          if m == null then "" else head m
        ) ruleKeys
      );
    in
    hosts;

  generated = listToAttrs (
    mapAttrsToList (id: spec: {
      name = id + "-oci";
      value = mkServiceFromHits id spec matchesById.${id};
    }) serviceRegistry
  );

  matchedContainers = flatten (attrValues matchesById);

  unmatched = filter (c: !(builtins.elem c matchedContainers)) containers;

  _warnUnmatched =
    if unmatched == [ ] then
      null
    else
      builtins.trace (
        "oci-container extractor: UNMATCHED containers → "
        + (concatStringsSep ", " (map (c: "${c._name} (${c.image})") unmatched))
      ) null;
in
{
  options.topology.extractors.oci-container = {
    enable = mkEnableOption "OCI container extractor" // {
      default = true;
    };

    infoFn = mkOption {
      type = types.functionTo types.lines;
      default = _: "";
      description = "Custom container info extractor function";
    };

    detailsFn = mkOption {
      type = types.functionTo types.raw;
      default = _: { };
      description = "Custom additional detail sections extractor function";
    };

    lib = mkOption {
      type = types.attrs;
      default = {
        inherit traefikHostInfoFn;
        imageDetailsFn = c: { image.text = c.image; };
      };
      readOnly = true;
      description = "Helper functions that can be reused in infoFn/detailsFn";
    };
  };

  config.topology.self = mkIf config.topology.extractors.oci-container.enable {
    services = seq _warnUnmatched generated;
  };
}
