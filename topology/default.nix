{
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    attrNames
    concatLists
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
      description = "Which renderer to use for the default output. Availble options: ${toString availableRenderers}";
      type = types.nullOr (types.enum availableRenderers);
      default = "d2";
    };

    output = mkOption {
      description = "The derivation containing the rendered output";
      type = types.path;
      readOnly = true;
      defaultText = literalExpression ''config.renderers.${config.renderer}.output'';
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
    output =
      mkIf (config.renderer != null)
      (mkDefault config.renderers.${config.renderer}.output);

    nodes = aggregate ["nodes"];
  };
}
