{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    attrNames
    concatLines
    concatStringsSep
    flatten
    flip
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    optional
    replaceStrings
    ;
in {
  options.topology.extractors.services.enable = mkEnableOption "topology service extractor" // {default = true;};

  config.topology.self.services = mkIf config.topology.extractors.services.enable {
    adguardhome = mkIf config.services.adguardhome.enable {
      name = "AdGuard Home";
      icon = "services.adguardhome";
    };

    forgejo = mkIf config.services.forgejo.enable {
      name = "Forgejo";
      icon = "services.forgejo";
    };

    grafana = mkIf config.services.grafana.enable {
      name = "Grafana";
      icon = "services.grafana";
    };

    kanidm = mkIf config.services.kanidm.enableServer {
      name = "Kanidm";
      icon = "services.kanidm";
    };

    loki = mkIf config.services.loki.enable {
      name = "Loki";
      icon = "services.loki";
    };

    nginx = mkIf config.services.nginx.enable {
      name = "NGINX";
      icon = "services.nginx";
      details.reverse = let
        lines = flatten (flip mapAttrsToList config.services.nginx.virtualHosts (
          server: vh:
            flip mapAttrsToList vh.locations (
              path: location: let
                upstreamName = replaceStrings ["http://" "https://"] ["" ""] location.proxyPass;
                passTo =
                  if config.services.nginx.upstreams ? ${upstreamName}
                  then toString (attrNames config.services.nginx.upstreams.${upstreamName}.servers)
                  else location.proxyPass;
              in
                optional (path == "/" && location.proxyPass != null) "${server} -> ${passTo}"
            )
        ));
      in
        mkIf (lines != []) {text = concatLines lines;};
    };

    radicale = mkIf config.services.radicale.enable {
      name = "Radicale";
      icon = "services.radicale";
    };

    samba = mkIf config.services.samba.enable {
      name = "Samba";
      icon = "services.samba";
    };

    oauth2_proxy = mkIf config.services.oauth2_proxy.enable {
      name = "OAuth2 Proxy";
      icon = "services.oauth2-proxy";
      info = config.services.oauth2_proxy.httpAddress;
    };

    openssh = mkIf config.services.openssh.enable {
      hidden = mkDefault true; # Causes a lot of clutter
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
