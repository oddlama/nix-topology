{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkIf
    ;
in {
  topology.self.services = {
    vaultwarden = mkIf config.services.vaultwarden.enable {
      name = "Vaultwarden";
      icon = "${pkgs.vaultwarden.webvault}/share/vaultwarden/vault/images/safari-pinned-tab.svg";
    };
  };
}
