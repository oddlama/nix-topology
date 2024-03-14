{
  pkgs,
  nixosConfigurations,
  ...
}: let
  inherit
    (pkgs.lib)
    any
    attrNames
    attrValues
    concatLines
    concatStringsSep
    elem
    escapeXML
    flip
    filterAttrs
    imap0
    mapAttrs'
    nameValuePair
    mapAttrsToList
    optional
    optionalAttrs
    optionalString
    ;

  # global = {
  #   # global entities;
  # };

  # asjson = builtins.toFile "topology.dot" (
  #   builtins.toJSON (map (x: x.config.topology) (attrValues nixosConfigurations))
  # );

  colors.base00 = "#101419";
  colors.base01 = "#171B20";
  colors.base02 = "#21262e";
  colors.base03 = "#242931";
  colors.base03b = "#353c48";
  colors.base04 = "#485263";
  colors.base05 = "#b6beca";
  colors.base06 = "#dee1e6";
  colors.base07 = "#e3e6eb";
  colors.base08 = "#e05f65";
  colors.base09 = "#f9a872";
  colors.base0A = "#f1cf8a";
  colors.base0B = "#78dba9";
  colors.base0C = "#74bee9";
  colors.base0D = "#70a5eb";
  colors.base0E = "#c68aee";
  colors.base0F = "#9378de";

  nodesById = mapAttrs' (_: node: nameValuePair node.config.topology.id node) nixosConfigurations;

  isGuestOfAny = node: any (x: elem node x.config.topology.guests) (attrValues nodesById);
  rootNodes = filterAttrs (n: _: !(isGuestOfAny n)) nodesById;

  toD2 = node: let
    topo = node.config.topology;
  in ''
    ${topo.id}: |md
    # ${topo.id}

    ## Guests:
    ${concatLines (map (x: "- ${x}") topo.guests)}

    ## Disks:
    ${concatLines (mapAttrsToList (_: v: "- ${v.name}") topo.disks)}

    ## Interfaces:
    ${concatLines (mapAttrsToList (_: v: "- ${v.name}, mac ${toString v.mac}, addrs ${toString v.addresses}, network ${toString v.network}") topo.interfaces)}

    ## Firewall Zones:
    ${concatLines (mapAttrsToList (_: v: "- ${v.name}, mac ${toString v.mac}, addrs ${toString v.addresses}, network ${toString v.network}") topo.firewallRules)}
    |
  '';

  d2ForNodes = mapAttrs' (_: node: nameValuePair node.config.topology.id (toD2 node)) nodesById;
in
  pkgs.writeText "topology.d2" ''
    ${concatLines (map (x: d2ForNodes.${x}) (attrNames rootNodes))}
  ''
