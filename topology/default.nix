{
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    attrNames
    concatLines
    concatLists
    concatStringsSep
    filter
    filterAttrs
    flip
    getAttrFromPath
    literalExpression
    mapAttrsToList
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
    warnIf
    ;

  availableRenderers = attrNames (filterAttrs (_: v: v == "directory") (builtins.readDir ./renderers));
in {
  imports =
    map (x: ./renderers/${x}) (attrNames (builtins.readDir ./renderers))
    ++ flip map (attrNames (builtins.readDir ../options)) (x:
      import ../options/${x} (
        module:
          module
          // {
            # Set the correct filename for diagnostics
            _file = ../options/${x};
          }
      ));

  options = {
    nixosConfigurations = mkOption {
      description = ''
        The list of nixos configurations to process for topology rendering.
        All of these must include the relevant nixos topology module.
      '';
      type = types.unspecified;
    };

    renderer = mkOption {
      description = "Which renderer to use for the default output. Available options: ${toString availableRenderers}";
      type = types.nullOr (types.enum availableRenderers);
      default = "elk";
    };

    output = mkOption {
      description = "The derivation containing the rendered output";
      type = types.path;
      readOnly = true;
      defaultText = literalExpression ''config.renderers.${config.renderer}.output'';
    };

    lib = lib.mkOption {
      default = {};
      type = lib.types.attrsOf lib.types.attrs;
      description = lib.mdDoc ''
        This option allows modules to define helper functions, constants, etc.
      '';
    };

    assertions = mkOption {
      internal = true;
      default = [];
      example = [
        {
          assertion = false;
          message = "you can't enable this for that reason";
        }
      ];
      description = lib.mdDoc ''
        This option allows modules to express conditions that must
        hold for the evaluation of the topology configuration to
        succeed, along with associated error messages for the user.
      '';
      type = types.listOf (types.submodule {
        options = {
          assertion = mkOption {
            description = "The thing to assert.";
            type = types.bool;
          };

          message = mkOption {
            description = "The error message.";
            type = types.str;
          };
        };
      });
    };

    warnings = mkOption {
      internal = true;
      default = [];
      example = ["This is deprecated for that reason"];
      description = lib.mdDoc ''
        This option allows modules to show warnings to users during
        the evaluation of the topology configuration.
      '';
      type = types.listOf types.str;
    };

    topology.isMainModule = mkOption {
      description = "Whether this is the toplevel topology module.";
      readOnly = true;
      internal = true;
      default = true;
      type = types.bool;
    };
  };

  config = let
    # Aggregates all values for an option from each host
    aggregate = optionPath:
      mkMerge (
        concatLists (flip mapAttrsToList config.nixosConfigurations (
          name: cfg:
            builtins.addErrorContext "while aggregating topology definitions from self.nixosConfigurations.${name} into toplevel topology:" (
              getAttrFromPath (["options" "topology"] ++ optionPath ++ ["definitions"]) cfg
            )
        ))
      );
  in {
    output = let
      failedAssertions = map (x: x.message) (filter (x: !x.assertion) config.assertions);
    in
      if failedAssertions != []
      then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
      else
        warnIf (config.warnings != [])
        (concatLines (["The following warnings were raised during evaluation:"] ++ config.warnings))
        (mkIf (config.renderer != null) (mkDefault config.renderers.${config.renderer}.output));

    nodes = aggregate ["nodes"];
    networks = aggregate ["networks"];
  };
}
