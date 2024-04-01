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
    mkMerge
    optional
    replaceStrings
    ;
in {
  options.topology.extractors.services.enable = mkEnableOption "topology service extractor" // {default = true;};

  config.topology.self.services = mkIf config.topology.extractors.services.enable {
    adguardhome = let
      address = config.services.adguardhome.settings.bind_host or null;
      port = config.services.adguardhome.settings.bind_port or null;
    in
      mkIf config.services.adguardhome.enable {
        name = "AdGuard Home";
        icon = "services.adguardhome";
        details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
      };

    forgejo = let
      address = config.services.forgejo.settings.server.HTTP_ADDR or null;
      port = config.services.forgejo.settings.server.HTTP_PORT or null;
    in
      mkIf config.services.forgejo.enable {
        name =
          if config.services.forgejo.settings ? DEFAULT.APP_NAME
          then "Forgejo (${config.services.forgejo.settings.DEFAULT.APP_NAME})"
          else "Forgejo";
        icon = "services.forgejo";
        info = mkIf (config.services.forgejo.settings ? server.ROOT_URL) config.services.forgejo.settings.server.ROOT_URL;
        details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
      };

    grafana = let
      address = config.services.grafana.settings.server.http_addr or null;
      port = config.services.grafana.settings.server.http_port or null;
    in
      mkIf config.services.grafana.enable {
        name = "Grafana";
        icon = "services.grafana";
        info = config.services.grafana.settings.server.root_url;
        details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
      };

    kanidm = mkIf config.services.kanidm.enableServer {
      name = "Kanidm";
      icon = "services.kanidm";
      info = config.services.kanidm.serverSettings.origin;
      details.listen.text = config.services.kanidm.serverSettings.bindaddress;
    };

    loki = let
      address = config.services.loki.configuration.server.http_listen_address or null;
      port = config.services.loki.configuration.server.http_listen_port or null;
    in
      mkIf config.services.loki.enable {
        name = "Loki";
        icon = "services.loki";
        details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
      };

    nginx = mkIf config.services.nginx.enable {
      name = "NGINX";
      icon = "services.nginx";
      details = let
        reverseProxies = flatten (flip mapAttrsToList config.services.nginx.virtualHosts (
          server: vh:
            flip mapAttrsToList vh.locations (
              path: location: let
                upstreamName = replaceStrings ["http://" "https://"] ["" ""] location.proxyPass;
                passTo =
                  if config.services.nginx.upstreams ? ${upstreamName}
                  then toString (attrNames config.services.nginx.upstreams.${upstreamName}.servers)
                  else location.proxyPass;
              in
                optional (path == "/" && location.proxyPass != null) {
                  ${server} = {text = passTo;};
                }
            )
        ));
      in
        mkMerge reverseProxies;
    };

    radicale = mkIf config.services.radicale.enable {
      name = "Radicale";
      icon = "services.radicale";
      details.listen = mkIf (config.services.radicale.settings ? server.hosts) {text = toString config.services.radicale.settings.server.hosts;};
    };

    samba = mkIf config.services.samba.enable {
      name = "Samba";
      icon = "services.samba";
      details.shares = let
        shares = attrNames config.services.samba.shares;
      in
        mkIf (shares != []) {text = concatLines shares;};
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
