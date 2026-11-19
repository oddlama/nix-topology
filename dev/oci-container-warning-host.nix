# A host for dev/oci-container-warning-test.nix, evaluated by a nested nix-instantiate
{
  nixpkgs,
  topology,
  system,
  warnUnmatched ? true,
  hideMystery ? false,
}:
import "${nixpkgs}/nixos/lib/eval-config.nix" {
  inherit system;
  modules = [
    "${topology}/nixos/module.nix"
    {
      fileSystems."/" = {
        device = "/dev/null";
        fsType = "ext4";
      };
      boot.loader.grub.device = "/dev/null";
      system.stateVersion = "25.11";

      virtualisation.oci-containers.containers = {
        jellyfin.image = "jellyfin/jellyfin";
        mystery.image = "ghcr.io/example/mystery:1";
      };
      topology.extractors.oci-container = { inherit warnUnmatched; };
      topology.serviceRegistry.mystery = {
        hidden = true;
        oci.repos = if hideMystery then [ "example/mystery" ] else [ ];
      };
    }
  ];
}
