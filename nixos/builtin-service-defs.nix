{ lib }:
let
  inherit (lib)
    attrNames
    concatLines
    concatStringsSep
    elemAt
    filter
    filterAttrs
    flatten
    flip
    forEach
    genAttrs
    hasPrefix
    head
    imap0
    length
    listToAttrs
    map
    mapAttrsToList
    mkIf
    mkMerge
    optional
    optionalAttrs
    optionalString
    remove
    removePrefix
    removeSuffix
    replaceStrings
    splitString
    tail
    ;
in
{
  adguardhome = {
    name = "AdGuard Home";
    icon = "services.adguardhome";
    nixos = {
      path = [
        "services"
        "adguardhome"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          address = cfg.host or null;
          port = cfg.port or null;
        in
        mkIf (address != null && port != null) {
          listen = {
            text = "${address}:${toString port}";
          };
        };
    };
    oci = {
      repos = [ "adguard/adguardhome" ];
    };
  };
  alloy = {
    name = "Alloy";
    icon = "services.alloy";
    nixos = {
      path = [
        "services"
        "alloy"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = _: { };
    };
    oci = {
      repos = [ "grafana/alloy" ];
    };
  };
  anki = {
    name = "Anki";
    icon = "services.anki";
    nixos = {
      path = [
        "services"
        "anki-sync-server"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.address}:${toString cfg.port}";
          };
        };
    };
  };
  atuin = {
    name = "Atuin";
    icon = "services.atuin";
    nixos = {
      path = [
        "services"
        "atuin"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.host}:${toString cfg.port}";
          };
        };
    };
    oci = {
      repos = [ "atuinsh/atuin" ];
    };
  };
  authelia = {
    name = "Authelia";
    icon = "services.authelia";
    nixos = {
      path = [
        "services"
        "authelia"
      ];
      enabled = cfg: (cfg.instances or { }) != { };
      detailsFn =
        cfg:
        let
          instances = filterAttrs (_: v: v.enable) cfg.instances;
        in
        listToAttrs (
          mapAttrsToList (name: v: {
            inherit name;
            value = {
              text = "${v.settings.server.host}:${toString v.settings.server.port}";
            };
          }) instances
        );
    };
    oci = {
      repos = [ "authelia/authelia" ];
    };
  };
  blocky = {
    name = "Blocky";
    icon = "services.blocky";
    nixos = {
      path = [
        "services"
        "blocky"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        listToAttrs (
          mapAttrsToList (n: v: {
            name = "listen.${n}";
            value = {
              text = toString v;
            };
          }) (cfg.settings.ports or { })
        );
    };
    oci = {
      repos = [
        "spx01/blocky"
        "0xerr0r/blocky"
      ];
    };
  };
  caddy = {
    name = "Caddy";
    icon = "services.caddy";
    nixos = {
      path = [
        "services"
        "caddy"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        genAttrs (mapAttrsToList (name: _: name) (cfg.virtualHosts or { })) (name: {
          text = concatStringsSep " " (
            map (line: removePrefix "reverse_proxy " (removeSuffix " {" line)) (
              filter (line: hasPrefix "reverse_proxy " line) (
                splitString "\n" (cfg.virtualHosts.${name}.extraConfig or "")
              )
            )
          );
        });
    };
    oci = {
      repos = [ "caddy" ];
    };
  };
  code-server = {
    name = "Code Server";
    icon = "services.code-server";
    nixos = {
      path = [
        "services"
        "code-server"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          host = cfg.host or null;
          port = cfg.port or null;
        in
        mkIf (host != null && port != null) {
          listen = {
            text = "${host}:${toString port}";
          };
        };
    };
    oci = {
      repos = [
        "codercom/code-server"
        "linuxserver/code-server"
      ];
    };
  };
  coder = {
    name = "Coder";
    icon = "services.coder";
    nixos = {
      path = [
        "services"
        "coder"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          listenAddress = cfg.listenAddress or null;
        in
        mkIf (listenAddress != null) {
          listen = {
            text = listenAddress;
          };
        };
      infoFn = cfg: cfg.accessUrl;
    };
    oci = {
      repos = [ "coder/coder" ];
    };
  };
  dnsmasq = {
    name = "Dnsmasq";
    icon = "services.dnsmasq";
    nixos = {
      path = [
        "services"
        "dnsmasq"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          addresses = cfg.settings.address or [ ];
        in
        listToAttrs (
          forEach (forEach addresses (x: splitString "/" (removePrefix "/" x))) (x: {
            name = head x;
            value = {
              text = head (tail x);
            };
          })
        );
    };
  };
  esphome = {
    name = "ESPHome";
    icon = "services.esphome";
    nixos = {
      path = [
        "services"
        "esphome"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text =
            if cfg.enableUnixSocket or false then
              "/run/esphome/esphome.sock"
            else
              "${cfg.address}:${toString cfg.port}";
        };
      };
    };
    oci = {
      repos = [ "esphome/esphome" ];
    };
  };
  fail2ban = {
    name = "Fail2Ban";
    icon = "services.fail2ban";
    nixos = {
      path = [
        "services"
        "fail2ban"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = _: { };
    };
    oci = {
      repos = [
        "linuxserver/fail2ban"
        "crazymax/fail2ban"
      ];
    };
  };
  firefox-syncserver = {
    name = "Firefox Syncserver";
    icon = "services.firefox-syncserver";
    nixos = {
      path = [
        "services"
        "firefox-syncserver"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: mkIf (cfg.singleNode.enable or false) cfg.singleNode.url;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.settings.host or "127.0.0.1"}:${toString cfg.settings.port}";
        };
      };
    };
  };
  forgejo = {
    name = "Forgejo";
    icon = "services.forgejo";
    nixos = {
      path = [
        "services"
        "forgejo"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: mkIf (cfg.settings ? server.ROOT_URL) cfg.settings.server.ROOT_URL;
      detailsFn = cfg: {
        name = {
          text =
            if cfg.settings ? DEFAULT.APP_NAME then "Forgejo (${cfg.settings.DEFAULT.APP_NAME})" else "Forgejo";
        };
        listen = mkIf (
          (cfg.settings.server.HTTP_ADDR or null) != null && (cfg.settings.server.HTTP_PORT or null) != null
        ) { text = "${cfg.settings.server.HTTP_ADDR}:${toString cfg.settings.server.HTTP_PORT}"; };
      };
    };
    oci = {
      repos = [ "forgejo/forgejo" ];
    };
  };
  gitea = {
    name = "gitea";
    icon = "services.gitea";
    nixos = {
      path = [
        "services"
        "gitea"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: mkIf (cfg.settings ? server.ROOT_URL) cfg.settings.server.ROOT_URL;
      detailsFn = cfg: {
        name = {
          text =
            if cfg.settings ? DEFAULT.APP_NAME then "gitea (${cfg.settings.DEFAULT.APP_NAME})" else "gitea";
        };
        listen = mkIf (
          (cfg.settings.server.HTTP_ADDR or null) != null && (cfg.settings.server.HTTP_PORT or null) != null
        ) { text = "${cfg.settings.server.HTTP_ADDR}:${toString cfg.settings.server.HTTP_PORT}"; };
      };
    };
    oci = {
      repos = [
        "gitea"
        "gitea/gitea"
        "linuxserver/gitea"
      ];
    };
  };
  glance = {
    name = "Glance";
    icon = "services.glance";
    nixos = {
      path = [
        "services"
        "glance"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.settings.server.host}:${toString cfg.settings.server.port}";
          };
        };
    };
    oci = {
      repos = [ "glanceapp/glance" ];
    };
  };
  grafana = {
    name = "Grafana";
    icon = "services.grafana";
    nixos = {
      path = [
        "services"
        "grafana"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: cfg.settings.server.root_url;
      detailsFn = cfg: {
        listen = mkIf (
          (cfg.settings.server.http_addr or null) != null && (cfg.settings.server.http_port or null) != null
        ) { text = "${cfg.settings.server.http_addr}:${toString cfg.settings.server.http_port}"; };
        plugins = mkIf ((cfg.declarativePlugins or null) != null) {
          text = concatStringsSep "\n" (map (p: p.name) cfg.declarativePlugins);
        };
      };
    };
    oci = {
      repos = [
        "grafana/grafana"
        "grafana/grafana-enterprise"
        "grafana/grafana-oss"
      ];
    };
  };
  harmonia = {
    name = "Harmonia";
    icon = "services.not-available";
    nixos = {
      path = [
        "services"
        "harmonia"
      ];
      enabled = cfg: cfg.enable or (cfg.cache.enable or false);
      detailsFn = _: { };
    };
  };
  headscale = {
    name = "Headscale";
    icon = "services.headscale";
    nixos = {
      path = [
        "services"
        "headscale"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: cfg.settings.server_url;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.address}:${toString cfg.port}";
        };
      };
    };
    oci = {
      repos = [
        "headscale/headscale"
        "juanfont/headscale"
      ];
    };
  };
  hickory-dns = {
    name = "Hickory DNS";
    icon = "services.hickory-dns";
    nixos = {
      path = [
        "services"
        "hickory-dns"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen_ipv4 = {
          text = toString (
            map (addr: "${addr}:${toString cfg.settings.listen_port}") cfg.settings.listen_addrs_ipv4
          );
        };
        listen_ipv6 = {
          text = toString (
            map (addr: "${addr}:${toString cfg.settings.listen_port}") cfg.settings.listen_addrs_ipv6
          );
        };
      };
    };
    oci = {
      repos = [ "hickorydns/hickory-dns" ];
    };
  };
  home-assistant = {
    name = "Home Assistant";
    icon = "services.home-assistant";
    nixos = {
      path = [
        "services"
        "home-assistant"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = toString (
            flip map cfg.config.http.server_host (addr: "${addr}:${toString cfg.config.http.server_port}")
          );
        };
      };
    };
    oci = {
      repos = [
        "home-assistant/home-assistant"
        "linuxserver/homeassistant"
      ];
    };
  };
  hydra = {
    name = "Hydra";
    icon = "devices.nixos";
    nixos = {
      path = [
        "services"
        "hydra"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: cfg.hydraURL;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.listenHost}:${toString cfg.port}";
        };
      };
    };
  };
  i2p = {
    name = "I2P";
    icon = "services.i2p";
    nixos = {
      path = [
        "services"
        "i2pd"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = _: { };
    };
    oci = {
      repos = [ "purplei2p/i2pd" ];
    };
  };
  immich = {
    name = "Immich";
    icon = "services.immich";
    nixos = {
      path = [
        "services"
        "immich"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.host}:${toString cfg.port}";
          };
        };
    };
    oci = {
      repos = [
        "immich-app/immich-server"
        "imagegenius/immich"
      ];
    };
  };
  influxdb2 = {
    name = "InfluxDB v2";
    icon = "services.influxdb2";
    nixos = {
      path = [
        "services"
        "influxdb2"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = cfg.settings.http-bind-address or "localhost:8086";
        };
      };
    };
    oci = {
      repos = [ "influxdb" ];
    };
  };
  invidious = {
    name = "Invidious";
    icon = "services.invidious";
    nixos = {
      path = [
        "services"
        "invidious"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.address}:${toString cfg.port}";
        };
      };
    };
    oci = {
      repos = [ "invidious/invidious" ];
    };
  };
  jellyfin = {
    name = "Jellyfin";
    icon = "services.jellyfin";
    nixos = {
      path = [
        "services"
        "jellyfin"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        listToAttrs (
          mapAttrsToList
            (n: v: {
              name = "listen.${n}";
              value = {
                text = "0.0.0.0:${toString v}";
              };
            })
            (
              optionalAttrs cfg.openFirewall {
                http = 8096;
                https = 8920;
                service-discovery = 1900;
                client-discovery = 7359;
              }
            )
        );
    };
    oci = {
      repos = [
        "jellyfin/jellyfin"
        "linuxserver/jellyfin"
      ];
    };
  };
  jellyseerr = {
    name = "Jellyseerr";
    icon = "services.jellyseerr";
    nixos = {
      path = [
        "services"
        "jellyseerr"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "0.0.0.0:${toString cfg.port}";
          };
        };
    };
    oci = {
      repos = [ "fallenbagel/jellyseerr" ];
    };
  };
  kanidm = {
    name = "Kanidm";
    icon = "services.kanidm";
    nixos = {
      path = [
        "services"
        "kanidm"
      ];
      enabled = cfg: cfg.enableServer or false;
      infoFn = cfg: cfg.serverSettings.origin;
      detailsFn = cfg: {
        listen = {
          text = cfg.serverSettings.bindaddress;
        };
      };
    };
    oci = {
      repos = [ "kanidm/server" ];
    };
  };
  karakeep = {
    name = "Karakeep";
    icon = "services.karakeep";
    nixos = {
      path = [
        "services"
        "karakeep"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = _: { };
    };
    oci = {
      repos = [ "karakeep-app/karakeep" ];
    };
  };
  kavita = {
    name = "Kavita";
    icon = "services.kavita";
    nixos = {
      path = [
        "services"
        "kavita"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "0.0.0.0:${toString cfg.settings.Port}";
        };
      };
    };
    oci = {
      repos = [
        "kareadita/kavita"
        "linuxserver/kavita"
        "jvmilazz0/kavita"
      ];
    };
  };
  komga = {
    name = "Komga";
    icon = "services.komga";
    nixos = {
      path = [
        "services"
        "komga"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "0.0.0.0:${toString cfg.settings.server.port}";
          };
        };
    };
    oci = {
      repos = [ "gotson/komga" ];
    };
  };
  languagetool = {
    name = "Languagetool";
    icon = "services.languagetool";
    nixos = {
      path = [
        "services"
        "languagetool"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "127.0.0.1:${toString cfg.port}";
        };
      };
    };
    oci = {
      repos = [ "erikvl87/languagetool" ];
    };
  };
  libretranslate = {
    name = "Libretranslate";
    icon = "services.libretranslate";
    nixos = {
      path = [
        "services"
        "libretranslate"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.host}:${toString cfg.port}";
        };
      };
    };
    oci = {
      repos = [ "libretranslate/libretranslate" ];
    };
  };
  lidarr = {
    name = "Lidarr";
    icon = "services.lidarr";
    nixos = {
      path = [
        "services"
        "lidarr"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "0.0.0.0:8686";
          };
        };
    };
    oci = {
      repos = [
        "linuxserver/lidarr"
        "hotio/lidarr"
      ];
    };
  };
  loki = {
    name = "Loki";
    icon = "services.loki";
    nixos = {
      path = [
        "services"
        "loki"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf
          (
            (cfg.configuration.server.http_listen_address or null) != null
            && (cfg.configuration.server.http_listen_port or null) != null
          )
          {
            listen = {
              text = "${cfg.configuration.server.http_listen_address}:${toString cfg.configuration.server.http_listen_port}";
            };
          };
    };
    oci = {
      repos = [ "grafana/loki" ];
    };
  };
  mastodon = {
    name = "Mastodon";
    icon = "services.mastodon";
    nixos = {
      path = [
        "services"
        "mastodon"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: "https://${cfg.localDomain}";
      detailsFn = _: { };
    };
    oci = {
      repos = [
        "mastodon/mastodon"
        "linuxserver/mastodon"
        "tootsuite/mastodon"
      ];
    };
  };
  matrix-synapse = {
    name = "Matrix (Synapse)";
    icon = "services.matrix";
    nixos = {
      path = [
        "services"
        "matrix-synapse"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: cfg.settings.public_baseurl;
      detailsFn =
        cfg:
        let
          listener = head (cfg.settings.listeners or [ ]);
        in
        mkIf (listener != null) {
          listen = {
            text = "${head listener.bind_addresses}:${toString listener.port}";
          };
        };
    };
    oci = {
      repos = [ "matrixdotorg/synapse" ];
    };
  };
  mautrix-signal = {
    name = "mautrix-signal";
    icon = "services.mautrix-signal";
    nixos = {
      path = [
        "services"
        "mautrix-signal"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          address = cfg.settings.appservice.hostname or null;
          port = cfg.settings.appservice.port or null;
        in
        mkIf (address != null && port != null) {
          listen = {
            text = "${address}:${toString port}";
          };
        };
    };
    oci = {
      repos = [ "mautrix/signal" ];
    };
  };
  mautrix-whatsapp = {
    name = "mautrix-whatsapp";
    icon = "services.mautrix-whatsapp";
    nixos = {
      path = [
        "services"
        "mautrix-whatsapp"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          address = cfg.settings.appservice.hostname or null;
          port = cfg.settings.appservice.port or null;
        in
        mkIf (address != null && port != null) {
          listen = {
            text = "${address}:${toString port}";
          };
        };
    };
    oci = {
      repos = [ "dock.mau.fi/mautrix/whatsapp" ];
    };
  };
  meilisearch = {
    name = "Meilisearch";
    icon = "services.meilisearch";
    nixos = {
      path = [
        "services"
        "meilisearch"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.listenAddress}:${toString cfg.listenPort}";
        };
      };
    };
    oci = {
      repos = [ "getmeili/meilisearch" ];
    };
  };
  mosquitto = {
    name = "Mosquitto";
    icon = "services.mosquitto";
    nixos = {
      path = [
        "services"
        "mosquitto"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        listToAttrs (
          flip imap0
            (flip map cfg.listeners (l: rec {
              address = if l.address == null then "[::]" else l.address;
              listen = if l.port == 0 then address else "${address}:${toString l.port}";
            }))
            (
              i: l: {
                name = "listen[${toString i}]";
                value = {
                  text = l.listen;
                };
              }
            )
        );
    };
    oci = {
      repos = [ "eclipse-mosquitto" ];
    };
  };
  mpd = {
    name = "MPD";
    icon = "services.mpd";
    nixos = {
      path = [
        "services"
        "mpd"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "${
            if cfg.settings.bind_to_address == "any" then "0.0.0.0" else cfg.settings.bind_to_address
          }:${toString cfg.settings.port}";
        };
      };
    };
  };
  navidrome = {
    name = "Navidrome";
    icon = "services.navidrome";
    nixos = {
      path = [
        "services"
        "navidrome"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: mkIf (cfg.settings ? Address) cfg.settings.Address;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.settings.Address}:${toString cfg.settings.Port}";
          };
        };
    };
    oci = {
      repos = [ "deluan/navidrome" ];
    };
  };
  nextcloud = {
    name = "Nextcloud";
    icon = "services.nextcloud";
    nixos = {
      path = [
        "services"
        "nextcloud"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: "http${optionalString cfg.https "s"}://${cfg.hostName}";
      detailsFn = _: { };
    };
    oci = {
      repos = [
        "nextcloud"
        "linuxserver/nextcloud"
      ];
    };
  };
  nginx = {
    name = "NGINX";
    icon = "services.nginx";
    nixos = {
      path = [
        "services"
        "nginx"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          reverseProxies = flatten (
            flip mapAttrsToList (cfg.virtualHosts or { }) (
              server: vh:
              flip mapAttrsToList (vh.locations or { }) (
                path: location:
                let
                  upstreamName = replaceStrings [ "http://" "https://" ] [ "" "" ] location.proxyPass;
                  passTo =
                    if (cfg.upstreams or { }) ? ${upstreamName} then
                      toString (attrNames cfg.upstreams.${upstreamName}.servers)
                    else
                      location.proxyPass;
                in
                optional (path == "/" && location.proxyPass != null) {
                  ${server} = {
                    text = passTo;
                  };
                }
              )
            )
          );
        in
        mkMerge reverseProxies;
    };
    oci = {
      repos = [ "nginx" ];
    };
  };
  nix-serve = {
    name = "Nix Serve";
    icon = "devices.nixos";
    nixos = {
      path = [
        "services"
        "nix-serve"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.bindAddress}:${toString cfg.port}";
        };
      };
    };
  };
  oauth2-proxy = {
    name = "OAuth2 Proxy";
    icon = "services.oauth2-proxy";
    nixos = {
      path = [
        "services"
        "oauth2-proxy"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: cfg.httpAddress;
      detailsFn = _: { };
    };
    oci = {
      repos = [ "oauth2-proxy/oauth2-proxy" ];
    };
  };
  ollama = {
    name = "Ollama";
    icon = "services.ollama";
    nixos = {
      path = [
        "services"
        "ollama"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.host}:${toString cfg.port}";
          };
        };
    };
    oci = {
      repos = [ "ollama/ollama" ];
    };
  };
  open-webui = {
    name = "Open Webui";
    icon = "services.open-webui";
    nixos = {
      path = [
        "services"
        "open-webui"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.host}:${toString cfg.port}";
          };
        };
    };
    oci = {
      repos = [ "open-webui/open-webui" ];
    };
  };
  openssh = {
    name = "OpenSSH";
    icon = "services.openssh";
    hidden = true;
    nixos = {
      path = [
        "services"
        "openssh"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: "port: ${concatStringsSep ", " (map toString cfg.ports)}";
      detailsFn = _: { };
    };
  };
  owncast = {
    name = "Owncast";
    icon = "services.owncast";
    nixos = {
      path = [
        "services"
        "owncast"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.listen}:${toString cfg.port}";
          };
        };
    };
    oci = {
      repos = [ "owncast/owncast" ];
    };
  };
  paperless-ngx = {
    name = "Paperless-ngx";
    icon = "services.paperless-ngx";
    nixos = {
      path = [
        "services"
        "paperless"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: mkIf ((cfg.settings.PAPERLESS_URL or null) != null) cfg.settings.PAPERLESS_URL;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.address}:${toString cfg.port}";
        };
      };
    };
    oci = {
      repos = [
        "paperless-ngx/paperless-ngx"
        "linuxserver/paperless-ngx"
      ];
    };
  };
  plausible = {
    name = "Plausible";
    icon = "services.plausible";
    nixos = {
      path = [
        "services"
        "plausible"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          listenAddress = cfg.server.listenAddress or null;
          port = cfg.server.port or null;
        in
        mkIf (listenAddress != null && port != null) {
          listen = {
            text = "${listenAddress}:${toString port}";
          };
        };
      infoFn = cfg: cfg.server.baseUrl;
    };
    oci = {
      repos = [ "plausible/analytics" ];
    };
  };
  postgresql = {
    name = "PostgreSQL";
    icon = "services.postgresql";
    nixos = {
      path = [
        "services"
        "postgresql"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          port = cfg.settings.port or null;
        in
        mkIf (port != null) {
          listen = {
            text = "0.0.0.0:${toString port}";
          };
        };
    };
  };
  prometheus = {
    name = "Prometheus";
    icon = "services.prometheus";
    nixos = {
      path = [
        "services"
        "prometheus"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.listenAddress}:${toString cfg.port}";
        };
      };
    };
    oci = {
      repos = [ "prom/prometheus" ];
    };
  };
  prowlarr = {
    name = "Prowlarr";
    icon = "services.prowlarr";
    nixos = {
      path = [
        "services"
        "prowlarr"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "0.0.0.0:9696";
          };
        };
    };
    oci = {
      repos = [
        "linuxserver/prowlarr"
        "hotio/prowlarr"
      ];
    };
  };
  radarr = {
    name = "Radarr";
    icon = "services.radarr";
    nixos = {
      path = [
        "services"
        "radarr"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "0.0.0.0:7878";
          };
        };
    };
    oci = {
      repos = [
        "linuxserver/radarr"
        "hotio/radarr"
      ];
    };
  };
  radicale = {
    name = "Radicale";
    icon = "services.radicale";
    nixos = {
      path = [
        "services"
        "radicale"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf (cfg.settings ? server.hosts) {
          listen = {
            text = toString cfg.settings.server.hosts;
          };
        };
    };
    oci = {
      repos = [ "kozea/radicale" ];
    };
  };
  redlib = {
    name = "Redlib";
    icon = "services.redlib";
    nixos = {
      path = [
        "services"
        "redlib"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.address}:${toString cfg.port}";
          };
        };
    };
    oci = {
      repos = [ "redlib/redlib" ];
    };
  };
  samba = {
    name = "Samba";
    icon = "services.samba";
    nixos = {
      path = [
        "services"
        "samba"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          shares = remove "global" (attrNames cfg.settings);
        in
        mkIf (shares != [ ]) {
          shares = {
            text = concatLines shares;
          };
        };
    };
  };
  scrutiny = {
    name = "Scrutiny";
    icon = "services.scrutiny";
    nixos = {
      path = [
        "services"
        "scrutiny"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.settings.web.listen.host}:${toString cfg.settings.web.listen.port}";
          };
        };
    };
    oci = {
      repos = [ "analogj/scrutiny" ];
    };
  };
  searxng = {
    name = "SearXNG";
    icon = "services.searxng";
    nixos = {
      path = [
        "services"
        "searx"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          address = cfg.settings.server.bind_address or null;
          port = cfg.settings.server.port or null;
        in
        mkIf (address != null && port != null) {
          listen = {
            text = "${address}:${toString port}";
          };
        };
    };
    oci = {
      repos = [ "searxng/searxng" ];
    };
  };
  sonarr = {
    name = "Sonarr";
    icon = "services.sonarr";
    nixos = {
      path = [
        "services"
        "sonarr"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "0.0.0.0:8989";
          };
        };
    };
    oci = {
      repos = [
        "linuxserver/sonarr"
        "hotio/sonarr"
      ];
    };
  };
  static-web-server = {
    name = "Static Web Server";
    icon = "devices.nixos";
    nixos = {
      path = [
        "services"
        "static-web-server"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = toString cfg.listen;
        };
        root = {
          text = toString cfg.root;
        };
      };
    };
    oci = {
      repos = [ "static-web-server/static-web-server" ];
    };
  };
  step-ca = {
    name = "step-ca";
    icon = "services.step-ca";
    nixos = {
      path = [
        "services"
        "step-ca"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        mkIf cfg.openFirewall {
          listen = {
            text = "${cfg.address}:${toString cfg.port}";
          };
        };
    };
    oci = {
      repos = [ "smallstep/step-ca" ];
    };
  };
  stirling-pdf = {
    name = "Stirling-PDF";
    icon = "services.stirling-pdf";
    nixos = {
      path = [
        "services"
        "stirling-pdf"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          address = cfg.environment.SERVER_HOST or null;
          port = cfg.environment.SERVER_PORT or null;
        in
        mkIf (address != null && port != null) {
          listen = {
            text = "${address}:${toString port}";
          };
        };
    };
    oci = {
      repos = [ "stirling-tools/stirling-pdf" ];
    };
  };
  tabby = {
    name = "Tabby";
    icon = "services.tabby";
    nixos = {
      path = [
        "services"
        "tabby"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.host}:${toString cfg.port}";
        };
      };
    };
    oci = {
      repos = [ "tabbyml/tabby" ];
    };
  };
  tor = {
    name = "Tor";
    icon = "services.tor";
    nixos = {
      path = [
        "services"
        "tor"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn = cfg: mkIf (cfg.relay.enable or false) "Role: ${cfg.relay.role}";
      detailsFn = _: { };
    };
  };
  traefik = {
    name = "Traefik";
    icon = "services.traefik";
    nixos = {
      path = [
        "services"
        "traefik"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          dynCfg = cfg.dynamicConfigOptions;
        in
        mkIf (length (attrNames dynCfg) > 0) (
          let
            formatOutput = mapAttrsToList (
              routerName: routerAttrs:
              let
                getServiceUrl =
                  serviceName:
                  let
                    service = dynCfg.http.services.${toString serviceName}.loadBalancer.servers or [ ];
                  in
                  if length service > 0 then (elemAt service 0).url else "invalid service";
                passText = toString (getServiceUrl routerAttrs.service);
              in
              {
                ${toString routerName} = {
                  text = passText;
                };
              }
            ) dynCfg.http.routers;
          in
          mkMerge formatOutput
        );
    };
    oci = {
      repos = [ "traefik" ];
    };
  };
  transmission = {
    name = "Transmission";
    icon = "services.transmission";
    nixos = {
      path = [
        "services"
        "transmission"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          address = cfg.settings.rpc-bind-address or null;
          port = cfg.settings.rpc-port or null;
        in
        mkIf (address != null && port != null) {
          listen = {
            text = "${address}:${toString port}";
          };
        };
    };
    oci = {
      repos = [ "linuxserver/transmission" ];
    };
  };
  vaultwarden = {
    name = "Vaultwarden";
    icon = "services.vaultwarden";
    nixos = {
      path = [
        "services"
        "vaultwarden"
      ];
      enabled = cfg: cfg.enable or false;
      infoFn =
        cfg:
        let
          domain = cfg.config.domain or cfg.config.DOMAIN or null;
        in
        mkIf (domain != null) domain;
      detailsFn =
        cfg:
        let
          address = cfg.config.rocketAddress or cfg.config.ROCKET_ADDRESS or null;
          port = cfg.config.rocketPort or cfg.config.ROCKET_PORT or null;
        in
        {
          listen = mkIf (address != null && port != null) { text = "${address}:${toString port}"; };
        };
    };
    oci = {
      repos = [
        "vaultwarden/server"
        "dani-garcia/vaultwarden"
      ];
    };
  };
  zigbee2mqtt = {
    name = "Zigbee2MQTT";
    icon = "services.zigbee2mqtt";
    nixos = {
      path = [
        "services"
        "zigbee2mqtt"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn =
        cfg:
        let
          mqttServer = cfg.settings.mqtt.server or null;
          address = cfg.settings.frontend.host or null;
          port = cfg.settings.frontend.port or null;
          listen =
            if address == null then
              null
            else if port == null then
              address
            else
              "${address}:${toString port}";
        in
        {
          listen = mkIf (listen != null) { text = listen; };
          mqtt = mkIf (mqttServer != null) { text = mqttServer; };
        };
    };
    oci = {
      repos = [ "koenkk/zigbee2mqtt" ];
    };
  };
  zipline = {
    name = "Zipline";
    icon = "services.zipline";
    nixos = {
      path = [
        "services"
        "zipline"
      ];
      enabled = cfg: cfg.enable or false;
      detailsFn = cfg: {
        listen = {
          text = "${cfg.settings.CORE_HOSTNAME}:${toString cfg.settings.CORE_PORT}";
        };
      };
    };
    oci = {
      repos = [ "diced/zipline" ];
    };
  };
}
