{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    concatLists
    flip
    mkDefault
    mkIf
    mkMerge
    optional
    ;
in {
  #config = mkIf config.systemd.network.enable {
  #  topology.interfaces = mkMerge (
  #    # Create interfaces based on systemd.network.netdevs
  #    concatLists (
  #      flip mapAttrsToList config.systemd.network.netdevs (
  #        _unit: netdev:
  #          optional (netdev ? netdevConfig.Name) {
  #            ${netdev.netdevConfig.Name} = {
  #              physical = mkDefault false;
  #            };
  #          }
  #      )
  #    )
  #    # Add interface configuration based on systemd.network.networks
  #    #++ concatLists (
  #    #  flip mapAttrsToList config.systemd.network.networks (
  #    #    _unit: network:
  #    #      optional (network ? matchConfig.Name) {
  #    #        ${network.networkConfig.Name} = {
  #    #        };
  #    #      }
  #    #  )
  #    #)
  #  );

  #  #self.interfaces = {
  #  #};
  #  #networks.somenet = {
  #  #  connections = [];
  #  #};
  #};
}
