{ lib, pkgs, ... }@args:
let
  inherit (lib) mkOption types;
in
{
  options.renderers.elk = {
    overviews = {
      services.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Include a services overview in the main output";
      };
      networks.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Include a networks overview in the main output";
      };
    };
    output = mkOption {
      description = "The derivation containing the rendered output";
      type = types.path;
      readOnly = true;
    };
  };

  config.renderers.elk.output = pkgs.runCommand "topology-diagrams" { } ''
    mkdir -p $out

    cp ${(import ./main.nix args).render} $out/main.svg
    cp ${(import ./network.nix args).render} $out/network.svg
  '';
}
