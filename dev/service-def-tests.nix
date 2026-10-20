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

  mkServiceTest =
    serviceName:
    let
      serviceDef = import (serviceDefDir + "/${serviceName}.nix") { inherit lib; };
      testSpec = serviceDef.test or { };
      optionPath = lib.splitString "." serviceDef.nixos.path;

      defaultConfig = lib.setAttrByPath optionPath { enable = true; };
      serviceConfig = testSpec.config or defaultConfig;
      # Enabling the service with only the settings NixOS requires must work
      minimalConfig = testSpec.minimalConfig or defaultConfig;

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
      service = forced.${serviceName} or null;
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
          assertion = minimalServices ? ${serviceName};
          message = "service does not appear when enabled with its minimal config";
        }
      ]
      ++ expectAssertions
      ++ (if testSpec ? assertions then testSpec.assertions forced else [ ]);
      failedAssertions = builtins.filter (a: !a.assertion) assertions;
      failureMessages = map (a: a.message) failedAssertions;

      appearsWhenDisabled = disabledServices ? ${serviceName};
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
