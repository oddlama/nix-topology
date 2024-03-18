{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    mkDefault
    mkIf
    ;
in {
  topology.self.services = {
    openssh = mkIf config.services.openssh.enable {
      hidden = mkDefault true; # Causes a lot of much clutter
      name = "OpenSSH";
      icon = "services.openssh";
      info = "port: ${concatStringsSep ", " (map toString config.services.openssh.ports)}";
    };

    vaultwarden = let
      domain = config.services.vaultwarden.config.domain or config.services.vaultwarden.config.DOMAIN or null;
      address = config.services.vaultwarden.config.rocketAddress or config.services.vaultwarden.config.ROCKET_ADDRESS or null;
      port = config.services.vaultwarden.config.rocketPort or config.services.vaultwarden.config.ROCKET_PORT or null;
    in
      mkIf config.services.vaultwarden.enable {
        name = "Vaultwarden";
        icon = "services.vaultwarden";
        info = mkIf (domain != null) domain;
        details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
      };
  };
}
