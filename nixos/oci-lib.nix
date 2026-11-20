# Backend-agnostic helpers for OCI container extractors: parsing image references,
# matching them against the `oci.repos` of the service registry and building services.
# An extractor only has to turn its containers into `mkContainer` values.
{ lib }:
let
  inherit (lib)
    all
    concatLists
    concatStringsSep
    filter
    foldl'
    hasInfix
    head
    init
    last
    length
    listToAttrs
    mapAttrsToList
    max
    mkDefault
    mkIf
    optional
    removePrefix
    sublist
    splitString
    tail
    ;

  # The first path component is a registry if it has a `.` or a `:` (a port), or is
  # `localhost`
  isRegistryLike = c: hasInfix "." c || hasInfix ":" c || c == "localhost";

  nullIfEmpty = s: if s == "" then null else s;

  # Splits a name into registry and path components. Docker Hub's `library/`
  # namespace is dropped, so `nginx` and `docker.io/library/nginx` are the same
  splitName =
    name:
    let
      comps = splitString "/" name;
      hasRegistry = length comps > 1 && isRegistryLike (head comps);
      registry = if hasRegistry then head comps else "docker.io";
      path = if hasRegistry then tail comps else comps;
    in
    {
      inherit hasRegistry registry;
      path =
        if registry == "docker.io" && length path > 1 && head path == "library" then tail path else path;
    };

  /**
    Parses an image reference into `{ reference, registry, repository, tag, digest }`.
    Never throws: `repository` is null if the reference has an empty path component,
    such as a podman rootfs path. `tag` and `digest` are null if the reference has none.
  */
  parseImage =
    reference:
    let
      ref = removePrefix "docker://" reference;
      atSplit = builtins.match "([^@]*)@(.*)" ref;
      beforeDigest = if atSplit == null then ref else head atSplit;
      digest = if atSplit == null then null else nullIfEmpty (last atSplit);

      comps = splitString "/" beforeDigest;
      # The tag is only in the last component, a `:` before it is a registry port
      tagSplit = builtins.match "([^:]*):(.*)" (last comps);
      tag = if tagSplit == null then null else nullIfEmpty (last tagSplit);
      name = concatStringsSep "/" (
        init comps ++ [ (if tagSplit == null then last comps else head tagSplit) ]
      );
      split = splitName name;

      valid = all (c: c != "") split.path;
    in
    {
      inherit reference;
      registry = if valid then split.registry else null;
      repository = if valid then concatStringsSep "/" split.path else null;
      tag = if valid then tag else null;
      digest = if valid then digest else null;
    };

  # How specific a matching pattern is: one with a registry beats one without,
  # then more components beat fewer. No image has 1000 components.
  parsePattern =
    pattern:
    let
      split = splitName pattern;
    in
    {
      inherit (split) path;
      registry = if split.hasRegistry then split.registry else null;
      score = (if split.hasRegistry then 1000 else 0) + length split.path;
    };

  # The pattern's score if it matches the parsed image, null otherwise
  matchScore =
    pattern: image:
    let
      p = parsePattern pattern;
      repo = splitString "/" image.repository;
      n = length p.path;
      m = length repo;
    in
    if
      image.repository != null
      && n <= m
      && sublist (m - n) n repo == p.path
      && (p.registry == null || p.registry == image.registry)
    then
      p.score
    else
      null;

  /**
    Whether a pattern from `oci.repos` matches a parsed image.
  */
  matches = pattern: image: matchScore pattern image != null;

  /**
    The ids of the entries whose patterns match the parsed image best, sorted.
    `entries` maps entry ids to lists of patterns.
  */
  bestMatches =
    entries: image:
    let
      # { id, score } for every entry with a matching pattern, score being its best one
      matched = concatLists (
        mapAttrsToList (
          id: patterns:
          let
            scores = filter (s: s != null) (map (p: matchScore p image) patterns);
          in
          optional (scores != [ ]) {
            inherit id;
            score = foldl' max 0 scores;
          }
        ) entries
      );
      top = foldl' max 0 (map (x: x.score) matched);
    in
    map (x: x.id) (filter (x: x.score == top) matched);

  /**
    The id of the entry that matches the parsed image best, or null. A tie picks the
    alphabetically first id with a warning.
  */
  resolve =
    entries: image:
    let
      ids = bestMatches entries image;
    in
    if ids == [ ] then
      null
    else if length ids > 1 then
      lib.warn "topology: the image `${image.reference}` matches the oci.repos of several registry entries equally well (${concatStringsSep ", " ids}), using `${head ids}`. Add a more specific pattern to the right entry." (
        head ids
      )
    else
      head ids;

  /**
    A normalized container, the same for every backend. `cfg` is the backend's raw
    configuration of the container.
  */
  mkContainer =
    {
      name,
      backend,
      image,
      cfg,
      ports ? [ ],
      labels ? { },
      environment ? { },
      volumes ? [ ],
    }:
    {
      inherit
        name
        backend
        cfg
        ports
        labels
        environment
        volumes
        ;
      image = parseImage image;
    };

  /**
    Builds the services of the containers, one `<source>-<container>` service per
    container whose image matches an entry of the registry. `source` names the
    extractor, it's the services' `source` and the prefix of their ids. Services with the same
    name get the container's name appended. Returns
    `{ services, unmatched }`, where `unmatched` is a list of `{ name, image }`.
  */
  mkServices =
    {
      registry,
      containers,
      config,
      infoFn,
      detailsFn,
      source ? "oci",
    }:
    let
      entries = lib.filterAttrs (_: repos: repos != [ ]) (
        lib.mapAttrs (_: spec: spec.oci.repos) registry
      );
      resolved = map (c: c // { serviceId = resolve entries c.image; }) containers;
      # The registry functions are called with these arguments
      withArgs = map (
        c:
        let
          spec = registry.${c.serviceId};
          args = {
            inherit (c) cfg;
            inherit config;
            container = removeAttrs c [
              "cfg"
              "serviceId"
            ];
          };
          baseName = if spec.oci.nameFn != null then spec.oci.nameFn args else spec.name;
        in
        c
        // {
          inherit spec args;
          # Entries without a name are shown with the container's name
          baseName = if baseName == "" then c.name else baseName;
        }
      ) (filter (c: c.serviceId != null) resolved);
      # Containers with the same name get the container's name appended
      countOf = baseName: length (filter (c: c.baseName == baseName) withArgs);

      mkService =
        c:
        let
          inherit (c) spec args baseName;
          specOci = spec.oci;
          name = if countOf baseName > 1 then "${baseName} (${c.name})" else baseName;
          # The registry entry's oci.infoFn wins over the extractor's infoFn, the extractor's
          # is only used when the entry's returns nothing
          registryInfo = specOci.infoFn args;
          info = if registryInfo != null && registryInfo != "" then registryInfo else infoFn args;
        in
        {
          name = "${source}-${c.name}";
          value = {
            inherit (c) serviceId;
            inherit source;
            name = mkDefault name;
            icon = mkDefault (if specOci.iconFn != null then specOci.iconFn args else spec.icon);
            hidden = mkDefault spec.hidden;
            # Undefined when empty: info is types.lines, "" would add an empty line
            info = mkIf (info != null && info != "") (mkDefault info);
            details = detailsFn args // specOci.detailsFn args;
          };
        };
    in
    {
      services = listToAttrs (map mkService withArgs);
      unmatched = map (c: {
        inherit (c) name;
        image = c.image.reference;
      }) (filter (c: c.serviceId == null) resolved);
    };

  /**
    The details the extractors show by default: the image without its digest, and
    the published ports if there are any.
  */
  defaultDetails =
    { container, ... }:
    {
      image.text = head (splitString "@" container.image.reference);
    }
    // lib.optionalAttrs (container.ports != [ ]) {
      ports.text = concatStringsSep " " container.ports;
    };
in
{
  inherit
    parseImage
    matches
    bestMatches
    resolve
    mkContainer
    mkServices
    defaultDetails
    ;
}
