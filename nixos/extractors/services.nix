{
  config,
  lib,
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
      info = "https://pw.example.com";
      details.listen.text = "[::]:3000";
    };
  };
}
