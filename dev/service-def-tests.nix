{
  self,
  pkgs,
  system,
  # Skip instead of fail on missing option paths, for nixpkgs versions that lag behind
  allowMissingOptions ? false,
}:
let
  inherit (pkgs) lib;
  nixosSystem = import "${pkgs.path}/nixos/lib/eval-config.nix";
  serviceDefDir = ../nixos/service-defs;
  serviceFiles = lib.filterAttrs (
    n: t: t == "regular" && lib.hasSuffix ".nix" n && n != "default.nix"
  ) (builtins.readDir serviceDefDir);

  baseEval = nixosSystem {
    inherit system;
    modules = [ self.nixosModules.topology ];
  };

  optionExists = path: lib.hasAttrByPath path baseEval.options;

  baseModules = [
    self.nixosModules.topology
    {
      networking.hostName = "test-host";
      fileSystems."/" = {
        device = "/dev/null";
        fsType = "ext4";
      };
      boot.loader.grub.device = "/dev/null";
    }
  ];

  # Evaluate with no services enabled to detect broken `enabled` functions
  disabledEval = nixosSystem {
    inherit system;
    modules = baseModules;
  };
  disabledServices =
    let
      s = disabledEval.config.topology.self.services;
    in
    builtins.deepSeq s s;

  ociLib = import ../nixos/oci-lib.nix { inherit lib; };
  serviceDefs = lib.mapAttrs' (
    filename: _:
    lib.nameValuePair (lib.removeSuffix ".nix" filename) (
      import (serviceDefDir + "/${filename}") { inherit lib; }
    )
  ) serviceFiles;
  ociEntries = lib.filterAttrs (_: repos: repos != [ ]) (
    lib.mapAttrs (_: def: def.oci.repos or [ ]) serviceDefs
  );

  # One container per pattern of every entry, named `<entry>-<n>`
  ociContainers = lib.listToAttrs (
    lib.concatLists (
      lib.mapAttrsToList (
        id: repos:
        lib.imap0 (i: pattern: lib.nameValuePair "${id}-${toString i}" { image = pattern; }) repos
      ) ociEntries
    )
  );
  ociEval = nixosSystem {
    inherit system;
    modules = baseModules ++ [ { virtualisation.oci-containers.containers = ociContainers; } ];
  };
  ociServices =
    let
      s = ociEval.config.topology.self.services;
    in
    builtins.deepSeq s s;

  # Each pattern, used as an image, resolves to its own entry without ties, and the
  # entry gets a service for each of its containers and no others. That registry,
  # tag and digest don't change matching is tested in oci-image-ref-test.nix.
  ociAssertions =
    serviceName:
    let
      repos = ociEntries.${serviceName} or [ ];
      ownContainers = lib.imap0 (i: _: "${serviceName}-${toString i}") repos;
      services = lib.attrNames (lib.filterAttrs (_: s: s.serviceId == serviceName) ociServices);
    in
    map (
      pattern:
      let
        got = ociLib.bestMatches ociEntries (ociLib.parseImage pattern);
      in
      {
        assertion = got == [ serviceName ];
        message = "OCI image ${pattern} should resolve to ${serviceName}, got ${builtins.toJSON got}";
      }
    ) repos
    ++ [
      {
        assertion = services == map (n: "oci-${n}") ownContainers;
        message = "OCI containers of all entries: expected services ${
          builtins.toJSON (map (n: "oci-${n}") ownContainers)
        } for ${serviceName}, got ${builtins.toJSON services}";
      }
    ];

  # `test.oci.containers` must give the services in `test.oci.expect`, by container name
  ociTestAssertions =
    serviceName: testOci:
    let
      services =
        let
          s =
            (nixosSystem {
              inherit system;
              modules = baseModules ++ [ { virtualisation.oci-containers.containers = testOci.containers; } ];
            }).config.topology.self.services;
        in
        builtins.deepSeq s s;
    in
    lib.concatLists (
      lib.mapAttrsToList (
        container: fields:
        let
          service = services."oci-${container}" or null;
        in
        if service == null then
          [
            {
              assertion = false;
              message = "test.oci: container ${container} has no service";
            }
          ]
        else
          lib.mapAttrsToList (field: want: {
            assertion = service.${field} == want && service.serviceId == serviceName;
            message = "test.oci: expected ${field} ${builtins.toJSON want} for container ${container}, got ${
              builtins.toJSON service.${field}
            } (serviceId ${service.serviceId})";
          }) fields
      ) testOci.expect
    );

  mkServiceTest =
    serviceName:
    let
      serviceDef = serviceDefs.${serviceName};
      testSpec = serviceDef.test or { };
      optionPath = lib.splitString "." serviceDef.nixos.path;

      # Services with `nixos.instances` are named `<service>-<instance>`,
      # the instance to check is set by `test.instance`
      instanced = serviceDef.nixos.instances or false;
      serviceKey =
        if !instanced then
          serviceName
        else if testSpec ? instance && testSpec ? config then
          "${serviceName}-${testSpec.instance}"
        else
          throw "Service def test '${serviceName}' failed: services with `nixos.instances` need `test.config` and `test.instance`";

      defaultConfig = lib.setAttrByPath optionPath { enable = true; };
      serviceConfig = testSpec.config or defaultConfig;
      # Enabling the service with only the settings NixOS requires must work
      minimalConfig = testSpec.minimalConfig or (if instanced then serviceConfig else defaultConfig);

      eval = nixosSystem {
        inherit system;
        modules = baseModules ++ [ serviceConfig ];
      };

      inherit (eval.config.topology.self) services;
      forced = builtins.deepSeq services services;

      minimalServices =
        let
          s =
            (nixosSystem {
              inherit system;
              modules = baseModules ++ [ minimalConfig ];
            }).config.topology.self.services;
        in
        builtins.addErrorContext "while evaluating service def test '${serviceName}' with its minimal config" (
          builtins.deepSeq s s
        );

      # `test.expect` compares fields of this service; `details.<section>` is that section's text
      expect = testSpec.expect or { };
      service = forced.${serviceKey} or null;
      actual =
        field:
        if lib.hasPrefix "details." field then
          service.details.${lib.removePrefix "details." field}.text or null
        else
          service.${field};
      expected =
        removeAttrs expect [ "details" ]
        // lib.mapAttrs' (section: lib.nameValuePair "details.${section}") (expect.details or { });
      expectAssertions =
        if service == null then
          lib.optional (expect != { }) {
            assertion = false;
            message = "service does not appear with its test config";
          }
        else
          lib.mapAttrsToList (field: want: {
            assertion = actual field == want;
            message = "expected ${field} ${builtins.toJSON want}, got ${builtins.toJSON (actual field)}";
          }) expected;

      assertions = [
        {
          assertion = minimalServices ? ${serviceKey};
          message = "service does not appear when enabled with its minimal config";
        }
      ]
      ++ expectAssertions
      ++ (if testSpec ? assertions then testSpec.assertions forced else [ ])
      ++ ociAssertions serviceName
      ++ lib.optionals (testSpec ? oci) (ociTestAssertions serviceName testSpec.oci);
      failedAssertions = builtins.filter (a: !a.assertion) assertions;
      failureMessages = map (a: a.message) failedAssertions;

      appearsWhenDisabled = disabledServices ? ${serviceKey};
    in
    if !optionExists optionPath && !allowMissingOptions then
      throw "Service def test '${serviceName}' failed: option path '${serviceDef.nixos.path}' does not exist"
    else if !optionExists optionPath then
      pkgs.runCommandLocal "service-def-test-${serviceName}-skipped" { } ''
        echo "skipped (option not available on this nixpkgs)" > $out
      ''
    else if appearsWhenDisabled then
      throw "Service def test '${serviceName}' failed: service appears in topology even when not enabled (check the 'enabled' function)"
    else if failedAssertions != [ ] then
      throw "Service def test '${serviceName}' failed:\n${lib.concatStringsSep "\n" failureMessages}"
    else
      pkgs.runCommandLocal "service-def-test-${serviceName}" { } ''
        echo "ok" > $out
      '';
in
lib.mapAttrs' (filename: _: {
  name = "service-def-${lib.removeSuffix ".nix" filename}";
  value = mkServiceTest (lib.removeSuffix ".nix" filename);
}) serviceFiles
