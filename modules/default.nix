{
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    attrNames
    filterAttrs
    literalExpression
    mkDefault
    mkIf
    mkOption
    types
    ;

  availableRenderers = attrNames (filterAttrs (_: v: v == "directory") (builtins.readDir ./renderers));
in {
  imports = map (x: ./renderers/${x}) (attrNames (builtins.readDir ./renderers));

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

  config = {
    output =
      mkIf (config.renderer != null)
      (mkDefault config.renderers.${config.renderer}.output);
  };
}
