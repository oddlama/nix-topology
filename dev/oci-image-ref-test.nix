{ pkgs, ... }:
let
  inherit (pkgs) lib;
  ociLib = import ../nixos/oci-lib.nix { inherit lib; };
  inherit (ociLib) parseImage matches bestMatches;

  digest = "sha256:${lib.fixedWidthString 64 "a" ""}";

  # --- Unit: references with their expected parts ---
  ref = registry: repository: tag: digest: {
    inherit
      registry
      repository
      tag
      digest
      ;
  };
  none = ref null null null null;
  parseCases = {
    "nginx" = ref "docker.io" "nginx" null null;
    "nginx:1.27" = ref "docker.io" "nginx" "1.27" null;
    "docker.io/nginx" = ref "docker.io" "nginx" null null;
    "docker://nginx" = ref "docker.io" "nginx" null null;
    # Docker Hub's library/ namespace is dropped, elsewhere it's an ordinary component
    "docker.io/library/nginx:1" = ref "docker.io" "nginx" "1" null;
    "library/nginx" = ref "docker.io" "nginx" null null;
    "library" = ref "docker.io" "library" null null;
    "docker://ghcr.io/a/b:t" = ref "ghcr.io" "a/b" "t" null;
    "lscr.io/linuxserver/jellyfin:10.10.3" = ref "lscr.io" "linuxserver/jellyfin" "10.10.3" null;
    "ghcr.io/immich-app/immich-server:release" =
      ref "ghcr.io" "immich-app/immich-server" "release"
        null;
    "localhost/foo" = ref "localhost" "foo" null null;
    "localhost:5000/foo" = ref "localhost:5000" "foo" null null;
    "localhost:5000/a/b:t@${digest}" = ref "localhost:5000" "a/b" "t" digest;
    "harbor.lan/proxy/jellyfin/jellyfin" = ref "harbor.lan" "proxy/jellyfin/jellyfin" null null;
    "123456789012.dkr.ecr.eu-west-1.amazonaws.com/library/redis:7" =
      ref "123456789012.dkr.ecr.eu-west-1.amazonaws.com" "library/redis" "7"
        null;
    "nginx@${digest}" = ref "docker.io" "nginx" null digest;
    "nginx:1@${digest}" = ref "docker.io" "nginx" "1" digest;
    # A single name is never a registry
    "localhost" = ref "docker.io" "localhost" null null;
    "localhost:5000" = ref "docker.io" "localhost" "5000" null;
    "nginx:" = ref "docker.io" "nginx" null null;
    # Not matchable
    "" = none;
    "/" = none;
    "a//b" = none;
    "ghcr.io/" = none;
    ":tag" = none;
    "@${digest}" = none;
    "/var/lib/containers/rootfs" = none;
    "https://ghcr.io/a/b" = none;
  };
  parseFailures = lib.concatLists (
    lib.mapAttrsToList (
      reference: want:
      let
        got = removeAttrs (parseImage reference) [ "reference" ];
      in
      lib.optional (got != want)
        "parseImage ${builtins.toJSON reference}: expected ${builtins.toJSON want}, got ${builtins.toJSON got}"
    ) parseCases
  );

  # --- Unit: patterns ---
  # "pattern | image" = whether the pattern matches the image
  matchCases = {
    "jellyfin | jellyfin/jellyfin" = true;
    "jellyfin | lscr.io/linuxserver/jellyfin" = true;
    "jellyfin | harbor.lan/proxy/jellyfin/jellyfin" = true;
    "jellyfin | hotio/jellyfin:release" = true;
    "jellyfin | jellyfin-vue" = false;
    "jellyfin | jellyfin/jellyfin-vue" = false;
    "jellyfin | myjellyfin" = false;
    "nginx | nginx" = true;
    "nginx | public.ecr.aws/docker/library/nginx" = true;
    "library/nginx | nginx:alpine" = true;
    "docker.io/nginx | nginx" = true;
    "docker.io/nginx | ghcr.io/library/nginx" = false;
    "vaultwarden/server | vaultwarden/server:1.32" = true;
    "vaultwarden/server | kanidm/server" = false;
    "lscr.io/linuxserver/jellyfin | lscr.io/linuxserver/jellyfin:latest" = true;
    "lscr.io/linuxserver/jellyfin | linuxserver/jellyfin" = false;
    "registry.lan/jf | registry.lan/mirror/jf" = true;
    "registry.lan/jf | jf" = false;
    "localhost:5000/foo | localhost:5000/foo:1" = true;
    "localhost:5000/foo | localhost:5001/foo" = false;
    "nginx | " = false;
  };
  matchFailures = lib.concatLists (
    lib.mapAttrsToList (
      case: want:
      let
        parts = lib.splitString " | " case;
        pattern = lib.elemAt parts 0;
        image = lib.elemAt parts 1;
      in
      lib.optional (
        matches pattern (parseImage image) != want
      ) "matches ${builtins.toJSON pattern} ${builtins.toJSON image}: expected ${builtins.toJSON want}"
    ) matchCases
  );

  # --- Unit: resolution ---
  resolveCases = [
    {
      what = "more components win";
      entries = {
        a = [ "server" ];
        b = [ "vaultwarden/server" ];
      };
      image = "vaultwarden/server:latest";
      want = [ "b" ];
    }
    {
      what = "a registry wins over more components";
      entries = {
        a = [ "proxy/jellyfin/jellyfin" ];
        b = [ "harbor.lan/jellyfin" ];
      };
      image = "harbor.lan/proxy/jellyfin/jellyfin";
      want = [ "b" ];
    }
    {
      what = "the best pattern of each entry counts";
      entries = {
        a = [
          "x"
          "foo/x"
        ];
        b = [ "x" ];
      };
      image = "foo/x";
      want = [ "a" ];
    }
    {
      what = "ties list all candidates";
      entries = {
        a = [ "x" ];
        b = [ "x" ];
      };
      image = "x";
      want = [
        "a"
        "b"
      ];
    }
    {
      what = "no match";
      entries.a = [ "x" ];
      image = "y";
      want = [ ];
    }
  ];
  resolveFailures = lib.concatMap (
    c:
    let
      got = bestMatches c.entries (parseImage c.image);
    in
    lib.optional (
      got != c.want
    ) "bestMatches (${c.what}): expected ${builtins.toJSON c.want}, got ${builtins.toJSON got}"
  ) resolveCases;
  resolveTie = ociLib.resolve {
    b = [ "x" ];
    a = [ "x" ];
  } (parseImage "x");
  resolveTieFailures = lib.optional (
    resolveTie != "a"
  ) "resolve: a tie should pick 'a', got ${builtins.toJSON resolveTie}";

  # --- Property: every combination of registry, path, tag, digest and transport ---
  registries = [
    {
      prefix = "";
      registry = "docker.io";
    }
    {
      prefix = "docker.io/";
      registry = "docker.io";
    }
    {
      prefix = "lscr.io/";
      registry = "lscr.io";
    }
    {
      prefix = "localhost/";
      registry = "localhost";
    }
    {
      prefix = "localhost:5000/";
      registry = "localhost:5000";
    }
    {
      prefix = "harbor.lan:8443/";
      registry = "harbor.lan:8443";
    }
  ];
  paths = [
    "jellyfin"
    "jellyfin/jellyfin"
    "linuxserver/jellyfin"
    "proxy/hub/jellyfin/jellyfin"
    "my_org/sub-team/jellyfin"
  ];
  tags = [
    ""
    ":latest"
    ":10.10.3-ls1"
  ];
  digests = [
    ""
    "@${digest}"
  ];
  transports = [
    ""
    "docker://"
  ];
  combinations = lib.cartesianProduct {
    registry = registries;
    path = paths;
    tag = tags;
    digest = digests;
    transport = transports;
  };
  propertyFailures = lib.concatMap (
    c:
    let
      reference = c.transport + c.registry.prefix + c.path + c.tag + c.digest;
      image = parseImage reference;
      expected = {
        inherit (c.registry) registry;
        repository = c.path;
        tag = if c.tag == "" then null else lib.removePrefix ":" c.tag;
        digest = if c.digest == "" then null else lib.removePrefix "@" c.digest;
      };
      got = removeAttrs image [ "reference" ];
      bare = parseImage (c.registry.prefix + c.path);
      check = what: ok: lib.optional (!ok) "${reference}: ${what}";
    in
    check "parses to ${builtins.toJSON expected}, got ${builtins.toJSON got}" (got == expected)
    ++ check "matches its last component" (matches "jellyfin" image)
    ++ check "matches its full path" (matches c.path image)
    ++ check "matches with its own registry" (
      c.registry.prefix == "" || matches (c.registry.prefix + c.path) image
    )
    ++ check "matches regardless of tag, digest and transport" (
      lib.all (p: matches p image == matches p bare) [
        "jellyfin"
        "linuxserver/jellyfin"
        "lscr.io/jellyfin"
        "docker.io/jellyfin"
        "localhost/jellyfin"
      ]
    )
    ++ check "doesn't match a component prefix" (
      !(lib.any (p: matches p image) [
        "jelly"
        "jellyfin-vue"
        "fin"
        "ellyfin"
      ])
    )
    ++ check "doesn't match another registry" (!matches "other.registry.example/jellyfin" image)
  ) combinations;

  # Both Docker Hub spellings are interchangeable in patterns too
  hubSpellings = [
    "docker.io/library/nginx"
    "docker.io/nginx"
  ];
  hubFailures = lib.concatMap (
    p:
    lib.concatMap (
      i: lib.optional (!matches p (parseImage i)) "Docker Hub spelling: ${p} should match ${i}"
    ) ([ "nginx" ] ++ hubSpellings)
  ) hubSpellings;

  failures =
    parseFailures
    ++ matchFailures
    ++ resolveFailures
    ++ resolveTieFailures
    ++ propertyFailures
    ++ hubFailures;
in
if failures != [ ] then
  throw "OCI image reference test failed:\n${lib.concatStringsSep "\n" failures}"
else
  pkgs.runCommandLocal "oci-image-ref-test" { } ''
    echo "OCI image reference test passed"
    echo "  - ${toString (lib.length (lib.attrNames parseCases))} parse cases: OK"
    echo "  - ${toString (lib.length (lib.attrNames matchCases))} match cases, ${toString (lib.length resolveCases)} resolution cases: OK"
    echo "  - ${toString (lib.length combinations)} combinations of registry, path, tag, digest and transport: OK"
    echo "ok" > $out
  ''
