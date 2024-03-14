{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;
in {
  options.renderers.d2 = {
    output = mkOption {
      description = "The derivation containing the rendered output";
      type = types.path;
      readOnly = true;
    };
  };

  config.renderers.d2.output = pkgs.runCommand "build-d2-topology" {} ''
    mkdir -p $out
    cp ${import ./network.nix {
      inherit pkgs;
      inherit (config) nixosConfigurations;
    }} $out/network.d2
  '';
}
