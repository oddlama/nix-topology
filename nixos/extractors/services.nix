{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    attrNames
    genAttrs
    concatLines
    concatStringsSep
    elemAt
    filterAttrs
    flatten
    flip
    forEach
    head
    imap0
    length
    listToAttrs
    mapAttrs
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    optional
    optionalString
    optionalAttrs
    replaceStrings
    splitString
    removePrefix
    removeSuffix
    hasPrefix
    filter
    tail
    ;
in {
  options.topology.extractors.services.enable = mkEnableOption "topology service extractor" // {default = true;};

  config.topology.self.services = mkIf config.topology.extractors.services.enable (
    {
      adguardhome = let
        address = config.services.adguardhome.host or null;
        port = config.services.adguardhome.port or null;
      in
        mkIf config.services.adguardhome.enable {
          name = "AdGuard Home";
          icon = "services.adguardhome";
          details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
        };

      anki = mkIf config.services.anki-sync-server.enable {
        name = "Anki";
        icon = "services.anki";
        details.listen = mkIf config.services.anki-sync-server.openFirewall {
          text = "${config.services.anki-sync-server.address}:${toString config.services.anki-sync-server.port}";
        };
      };

      alloy = mkIf config.services.alloy.enable {
        name = "Alloy";
        icon = "services.alloy";
      };

      atuin = mkIf config.services.atuin.enable {
        name = "Atuin";
        icon = "services.atuin";
        details.listen = mkIf config.services.atuin.openFirewall {text = "${config.services.atuin.host}:${toString config.services.atuin.port}";};
      };

      authelia = let
        instances =
          filterAttrs (_: v: v.enable) config.services.authelia.instances;
      in
        mkIf (instances != {}) {
          name = "Authelia";
          icon = "services.authelia";
          details = listToAttrs (mapAttrsToList (name: v: {
              inherit name;
              value.text = "${lib.strings.removeSuffix "/" (lib.strings.removePrefix "tcp://" v.settings.server.address)}";
            })
            instances);
        };

      blocky = mkIf config.services.blocky.enable {
        name = "Blocky";
        icon = "services.blocky";
        details = listToAttrs (mapAttrsToList (n: v: {
            name = "listen.${n}";
            value.text = toString v;
          })
          config.services.blocky.settings.ports);
      };

      caddy = mkIf config.services.caddy.enable {
        name = "Caddy";
        icon = "services.caddy";
        details = genAttrs (mapAttrsToList (name: _: name) config.services.caddy.virtualHosts) (name: {
          text =
            concatStringsSep " " # Turn the (possibly multiple) strings in the list into a single string
            
            (builtins.map
              (line: removePrefix "reverse_proxy " (removeSuffix " {" line)) # Remove the prefix and suffix, so only the list of hosts are left
              
              (filter (line: hasPrefix "reverse_proxy " line) # Filter out lines that don't start with reverse_proxy
                
                (splitString "\n" config.services.caddy.virtualHosts.${name}.extraConfig))); # Separate lines of string into list
        });
      };

      code-server = mkIf config.services.code-server.enable {
        name = "Code Server";
        icon = "services.code-server";
        details.listen.text = "${config.services.code-server.host}:${toString config.services.code-server.port}";
      };

      dnsmasq = mkIf config.services.dnsmasq.enable {
        name = "Dnsmasq";
        icon = "services.dnsmasq";
        details = let
          addresses = config.services.dnsmasq.settings.address or [];
        in
          listToAttrs (forEach
            (forEach addresses
              (x: (splitString "/" (removePrefix "/" x))))
            (x: {
              name = head x;
              value.text = head (tail x);
            }));
      };

      esphome = mkIf config.services.esphome.enable {
        name = "ESPHome";
        icon = "services.esphome";
        details.listen.text =
          if config.services.esphome.enableUnixSocket
          then "/run/esphome/esphome.sock"
          else "${config.services.esphome.address}:${toString config.services.esphome.port}";
      };

      fail2ban = mkIf config.services.fail2ban.enable {
        name = "Fail2Ban";
        icon = "services.fail2ban";
      };

      firefox-syncserver = mkIf config.services.firefox-syncserver.enable ({
          name = "Firefox Syncserver";
          icon = "services.firefox-syncserver";
          details.listen.text = "${config.services.firefox-syncserversettings.host or "127.0.0.1"}:${toString config.services.firefox-syncserver.settings.port}";
        }
        // (optionalAttrs config.services.firefox-syncserver.singleNode.enable {
          info = config.services.firefox-syncserver.singleNode.url;
        }));

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

      gitea = let
        address = config.services.gitea.settings.server.HTTP_ADDR or null;
        port = config.services.gitea.settings.server.HTTP_PORT or null;
      in
        mkIf config.services.gitea.enable {
          name =
            if config.services.gitea.settings ? DEFAULT.APP_NAME
            then "gitea (${config.services.gitea.settings.DEFAULT.APP_NAME})"
            else "gitea";
          icon = "services.gitea";
          info = mkIf (config.services.gitea.settings ? server.ROOT_URL) config.services.gitea.settings.server.ROOT_URL;
          details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
        };

      glance = mkIf config.services.glance.enable {
        name = "Glance";
        icon = "services.glance";
        details.listen = mkIf config.services.glance.openFirewall {text = "${config.services.glance.settings.server.host}:${toString config.services.glance.settings.server.port}";};
      };

      grafana = let
        address = config.services.grafana.settings.server.http_addr or null;
        port = config.services.grafana.settings.server.http_port or null;
        plugins = config.services.grafana.declarativePlugins;
      in
        mkIf config.services.grafana.enable {
          name = "Grafana";
          icon = "services.grafana";
          info = config.services.grafana.settings.server.root_url;
          details = {
            listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
            plugins = mkIf (plugins != null) {text = concatStringsSep "\n" (builtins.map (p: p.name) plugins);};
          };
        };

      headscale = mkIf config.services.headscale.enable {
        name = "Headscale";
        icon = "services.headscale";
        info = config.services.headscale.settings.server_url;
        details = {
          listen.text = "${config.services.headscale.address}:${toString config.services.headscale.port}";
        };
      };

      home-assistant = mkIf config.services.home-assistant.enable {
        name = "Home Assistant";
        icon = "services.home-assistant";
        details.listen.text = toString (
          flip map config.services.home-assistant.config.http.server_host (
            addr: "${addr}:${toString config.services.home-assistant.config.http.server_port}"
          )
        );
      };

      hydra = mkIf config.services.hydra.enable {
        name = "Hydra";
        icon = "devices.nixos";
        info = config.services.hydra.hydraURL;
        details.listen.text = "${config.services.hydra.listenHost}:${toString config.services.hydra.port}";
      };

      i2p = mkIf config.services.i2pd.enable {
        name = "I2P";
        icon = "services.i2p";
      };

      immich = mkIf (config.services.immich.enable or false) {
        name = "Immich";
        icon = "services.immich";
        details.listen = mkIf config.services.immich.openFirewall {text = "${config.services.immich.host}:${toString config.services.immich.port}";};
      };

      influxdb2 = mkIf config.services.influxdb2.enable {
        name = "InfluxDB v2";
        icon = "services.influxdb2";
        details.listen.text = config.services.influxdb2.settings.http-bind-address or "localhost:8086";
      };

      invidious = mkIf config.services.invidious.enable {
        name = "Invidious";
        icon = "services.invidious";
        details.listen.text = "${config.services.invidious.address}:${toString config.services.invidious.port}";
      };

      jellyfin = mkIf config.services.jellyfin.enable {
        name = "Jellyfin";
        icon = "services.jellyfin";
        details = listToAttrs (mapAttrsToList (n: v: {
            name = "listen.${n}";
            value.text = "0.0.0.0:${toString v}";
          })
          (optionalAttrs config.services.jellyfin.openFirewall {
            http = 8096;
            https = 8920;
            service-discovery = 1900;
            client-discovery = 7359;
          }));
      };

      jellyseerr = mkIf config.services.jellyseerr.enable {
        name = "Jellyseerr";
        icon = "services.jellyseerr";
        details.listen = mkIf config.services.jellyseerr.openFirewall {text = "0.0.0.0:${toString config.services.jellyseerr.port}";};
      };

      kanidm = mkIf config.services.kanidm.enableServer {
        name = "Kanidm";
        icon = "services.kanidm";
        info = config.services.kanidm.serverSettings.origin;
        details.listen.text = config.services.kanidm.serverSettings.bindaddress;
      };

      languagetool = mkIf config.services.languagetool.enable {
        name = "Languagetool";
        icon = "services.languagetool";
        details.listen.text = "127.0.0.1:${toString config.services.languagetool.port}";
      };

      lidarr = mkIf config.services.lidarr.enable {
        name = "Lidarr";
        icon = "services.lidarr";
        details.listen = mkIf config.services.lidarr.openFirewall {text = "0.0.0.0:8686";};
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

      mastodon = mkIf config.services.mastodon.enable {
        name = "Mastodon";
        icon = "services.mastodon";
        info = "https://${config.services.mastodon.localDomain}";
      };

      mosquitto = let
        listeners = flip map config.services.mosquitto.listeners (
          l: rec {
            address =
              if l.address == null
              then "[::]"
              else l.address;
            listen =
              if l.port == 0
              then address
              else "${address}:${toString l.port}";
          }
        );
      in
        mkIf config.services.mosquitto.enable {
          name = "Mosquitto";
          icon = "services.mosquitto";
          details = listToAttrs (flip imap0 listeners (i: l: {
            name = "listen[${toString i}]";
            value.text = l.listen;
          }));
        };

      nextcloud = mkIf config.services.nextcloud.enable {
        name = "Nextcloud";
        icon = "services.nextcloud";
        info = "http${
          optionalString config.services.nextcloud.https "s"
        }://${config.services.nextcloud.hostName}";
      };

      nix-serve = mkIf config.services.nix-serve.enable {
        name = "Nix Serve";
        icon = "devices.nixos";
        details.listen.text = "${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
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

      oauth2-proxy = mkIf config.services.oauth2-proxy.enable {
        name = "OAuth2 Proxy";
        icon = "services.oauth2-proxy";
        info = config.services.oauth2-proxy.httpAddress;
      };

      ollama = mkIf config.services.ollama.enable {
        name = "Ollama";
        icon = "services.ollama";
        details.listen = mkIf config.services.ollama.openFirewall {text = "${config.services.ollama.host}:${toString config.services.ollama.port}";};
      };

      open-webui = mkIf config.services.open-webui.enable {
        name = "Open Webui";
        icon = "services.open-webui";
        details.listen = mkIf config.services.open-webui.openFirewall {text = "${config.services.open-webui.host}:${toString config.services.open-webui.port}";};
      };

      openssh = mkIf config.services.openssh.enable {
        hidden = mkDefault true; # Causes a lot of clutter
        name = "OpenSSH";
        icon = "services.openssh";
        info = "port: ${concatStringsSep ", " (map toString config.services.openssh.ports)}";
      };

      paperless-ngx = let
        url = config.services.paperless.settings.PAPERLESS_URL or null;
      in
        mkIf config.services.paperless.enable {
          name = "Paperless-ngx";
          icon = "services.paperless-ngx";
          info = mkIf (url != null) url;
          details.listen.text = "${config.services.paperless.address}:${toString config.services.paperless.port}";
        };

      prometheus = mkIf config.services.prometheus.enable {
        name = "Prometheus";
        icon = "services.prometheus";
        details.listen.text = "${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
      };

      prowlarr = mkIf config.services.prowlarr.enable {
        name = "Prowlarr";
        icon = "services.prowlarr";
        details.listen = mkIf config.services.prowlarr.openFirewall {text = "0.0.0.0:9696";};
      };

      radarr = mkIf config.services.radarr.enable {
        name = "Radarr";
        icon = "services.radarr";
        details.listen = mkIf config.services.radarr.openFirewall {text = "0.0.0.0:7878";};
      };

      radicale = mkIf config.services.radicale.enable {
        name = "Radicale";
        icon = "services.radicale";
        details.listen = mkIf (config.services.radicale.settings ? server.hosts) {text = toString config.services.radicale.settings.server.hosts;};
      };

      redlib = mkIf config.services.redlib.enable {
        name = "Redlib";
        icon = "services.redlib";
        details.listen = mkIf config.services.redlib.openFirewall {text = "${config.services.redlib.address}:${toString config.services.redlib.port}";};
      };

      samba = mkIf config.services.samba.enable {
        name = "Samba";
        icon = "services.samba";
        details.shares = let
          shares = lib.remove "global" (attrNames config.services.samba.settings);
        in
          mkIf (shares != []) {text = concatLines shares;};
      };

      searxng = let
        address = config.services.searx.settings.server.bind_address or null;
        port = config.services.searx.settings.server.port or null;
      in
        mkIf config.services.searx.enable {
          name = "SearXNG";
          icon = "services.searxng";
          details.listen = lib.mkIf (address != null && port != null) {text = "${address}:${toString port}";};
        };

      sonarr = mkIf config.services.sonarr.enable {
        name = "Sonarr";
        icon = "services.sonarr";
        details.listen = mkIf config.services.sonarr.openFirewall {text = "0.0.0.0:8989";};
      };

      static-web-server = mkIf config.services.static-web-server.enable {
        name = "Static Web Server";
        icon = "devices.nixos";
        details = {
          listen.text = toString config.services.static-web-server.listen;
          root.text = toString config.services.static-web-server.root;
        };
      };

      stirling-pdf = let
        address = config.services.stirling-pdf.environment.SERVER_HOST or null;
        port = config.services.stirling-pdf.environment.SERVER_PORT or null;
      in
        mkIf config.services.stirling-pdf.enable {
          name = "Stirling-PDF";
          icon = "services.stirling-pdf";
          details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
        };

      tabby = mkIf config.services.tabby.enable {
        name = "Tabby";
        icon = "services.tabby";
        details.listen.text = "${config.services.tabby.host}:${toString config.services.tabby.port}";
      };

      tor = let
        _tor = config.services.tor;
      in
        mkIf _tor.enable {
          name = "Tor";
          icon = "services.tor";
          info = mkIf _tor.relay.enable "Role: ${_tor.relay.role}";
        };

      traefik = let
        dynCfg = config.services.traefik.dynamicConfigOptions;
      in
        mkIf config.services.traefik.enable {
          name = "Traefik";
          icon = "services.traefik";
          details = mkIf (length (attrNames dynCfg) > 0) (let
            formatOutput =
              mapAttrsToList (
                routerName: routerAttrs: let
                  getServiceUrl = serviceName: let
                    service = dynCfg.http.services.${toString serviceName}.loadBalancer.servers or [];
                  in
                    if length service > 0
                    then (elemAt service 0).url
                    else "invalid service";
                  passText = toString (getServiceUrl routerAttrs.service);
                in {
                  ${toString routerName} = {
                    text = passText;
                  };
                }
              )
              dynCfg.http.routers;
          in
            mkMerge formatOutput);
        };

      transmission = let
        address = config.services.transmission.settings.rpc-bind-address or null;
        port = config.services.transmission.settings.rpc-port or null;
      in
        mkIf config.services.transmission.enable {
          name = "Transmission";
          icon = "services.transmission";
          details.listen = mkIf (address != null && port != null) {text = "${address}:${toString port}";};
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

      zigbee2mqtt = let
        mqttServer = config.services.zigbee2mqtt.settings.mqtt.server or null;
        address = config.services.zigbee2mqtt.settings.frontend.host or null;
        port = config.services.zigbee2mqtt.settings.frontend.port or null;
        listen =
          if address == null
          then null
          else if port == null
          then address
          else "${address}:${toString port}";
      in
        mkIf config.services.zigbee2mqtt.enable {
          name = "Zigbee2MQTT";
          icon = "services.zigbee2mqtt";
          details.listen = mkIf (listen != null) {text = listen;};
          details.mqtt = mkIf (mqttServer != null) {text = mqttServer;};
        };
    }
    // flip mapAttrs config.services.restic.backups (
      backupName: cfg: {
        name = "Restic backup '${backupName}'";
        icon = "services.restic";
        info = mkIf (cfg.repository != null) cfg.repository;
        details.paths.text = toString cfg.paths;
      }
    )
  );
}
