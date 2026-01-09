/*
  A module to import into flakes based on flake-parts.
  Makes integration into a flake easy and tidy.
  See https://flake.parts, https://flake.parts/options/nix-topology
*/
{
  lib,
  self,
  config,
  flake-parts-lib,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      topology = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = lib.mapAttrs (
          _system: config':
          import ./. {
            inherit (config'.topology) pkgs;
            modules = config'.topology.modules ++ [
              { inherit (config'.topology) nixosConfigurations; }
            ];
          }
        ) config.allSystems;
        defaultText = "Automatically filled by nix-topology";
        readOnly = true;
        description = ''
          The evaluated topology configuration, for each of the specified systems.
          Build the output by running `nix build .#topology.$system.config.output`.
        '';
      };
    };

    perSystem = flake-parts-lib.mkPerSystemOption (
      {
        lib,
        pkgs,
        ...
      }:
      {
        options.topology = {
          nixosConfigurations = mkOption {
            type = types.lazyAttrsOf types.unspecified;
            description = "All nixosSystems that should be evaluated for topology definitions.";
            default = lib.filterAttrs (_: x: x.config ? topology) self.nixosConfigurations;
            defaultText = lib.literalExpression "lib.filterAttrs (_: x: x.config ? topology) self.nixosConfigurations";
          };
          pkgs = mkOption {
            type = types.unspecified;
            description = "The package set to use for the topology evaluation on this system.";
            default = pkgs.extend (import ./pkgs/default.nix);
            defaultText = lib.literalExpression "pkgs # (module argument)";
          };
          modules = mkOption {
            type = types.listOf types.unspecified;
            description = "A list of additional topology modules to evaluate in your global topology.";
            default = [ ];
          };
        };
      }
    );
  };
}
