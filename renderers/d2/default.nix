{pkgs, ...} @ attrs:
pkgs.runCommand "build-d2-topology" {} ''
  mkdir -p $out
  cp ${import ./network.nix attrs} $out/network.d2
''
