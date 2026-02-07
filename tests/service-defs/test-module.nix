{ pkgs, ... }:
let
  # Helper to create dummy secret files
  dummySecret = pkgs.writeText "dummy-secret" "dummy-secret-value";
  dummySecretKey = pkgs.writeText "dummy-key" "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
  dummyPrivateKey = pkgs.writeText "dummy-private-key" "not-a-real-key";
  dummyCert = pkgs.writeText "dummy-cert" ''
    -----BEGIN CERTIFICATE-----
    MIIBkTCB+wIJALQ2tZT1k6qwMA0GCSqGSIb3DQEBCwUAMBExDzANBgNVBAMMBmR1
    bW15MTAeFw0yMzAxMDEwMDAwMDBaFw0yNDAxMDEwMDAwMDBaMBExDzANBgNVBAMM
    BmR1bW15MTBcMA0GCSqGSIb3DQEBAQUAA0sAMEgCQQC7o96HtiKQFxmBvB3LtmGW
    fL+NtYH5gxLqT3C8kE6l3LxPz7t0H+Y6x4Q3Y8L3G8S3Z5D4E5s7Y7P2Q3K3KNXX
    AgMBAAGjUzBRMB0GA1UdDgQWBBRJFMRRqVJ3pDYJ2r8p2G5D0qr2QDAfBgNVHSME
    GDAWgBRJFMRRqVJ3pDYJ2r8p2G5D0qr2QDAPBgNVHRMBAf8EBTADAQH/MA0GCSqG
    SIb3DQEBCwUAA0EAT+2B3iF7V6q3nN6Q3V8E0W5B2M0Q3Y8L3G8S3Z5D4E5s7Y7P
    2Q3K3KNXX7o96HtiKQFxmBvB3LtmGWfL+NtYH5gxLqT3C8kE6l3LxPw==
    -----END CERTIFICATE-----
  '';
in
{
  # Basic system configuration
  networking.hostName = "test-services";
  system.stateVersion = "24.05";
  boot.loader.grub.device = "nodev";
  fileSystems."/" = {
    device = "/dev/null";
    fsType = "tmpfs";
  };

  # Allow unfree packages (needed for coder/terraform)
  nixpkgs.config.allowUnfree = true;
  # Allow insecure packages (olm needed by mautrix-signal)
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  # PostgreSQL - needed by several services
  services.postgresql = {
    enable = true;
    settings.port = 5432;
  };

  # MySQL - needed by some services (mastodon)
  services.mysql.package = pkgs.mariadb;

  services.alloy.enable = true;
  services.fail2ban.enable = true;
  services.harmonia.enable = true;
  services.karakeep.enable = true;
  services.i2pd.enable = true;
  services.openssh.enable = true;
  services.tor = {
    enable = true;
    relay.role = "relay";
  };

  services.mastodon = {
    enable = true;
    localDomain = "mastodon.example.com";
    configureNginx = false;
    smtp.fromAddress = "noreply@example.com";
    secretKeyBaseFile = "/var/lib/mastodon/secret_key_base";
    vapidPublicKeyFile = "/var/lib/mastodon/vapid_public_key";
    vapidPrivateKeyFile = "/var/lib/mastodon/vapid_private_key";
    streamingProcesses = 1;
  };

  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
  };

  services.code-server = {
    enable = true;
    host = "0.0.0.0";
    port = 4444;
  };

  services.esphome = {
    enable = true;
    address = "0.0.0.0";
    port = 6052;
  };

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "http://headscale.example.com";
      dns.base_domain = "example.com";
    };
  };

  services.invidious = {
    enable = true;
    address = "0.0.0.0";
    port = 3001;
  };

  services.languagetool = {
    enable = true;
    port = 8081;
  };

  services.libretranslate = {
    enable = true;
    host = "0.0.0.0";
    port = 5000;
  };

  services.meilisearch = {
    enable = true;
    listenAddress = "0.0.0.0";
    listenPort = 7700;
  };

  services.mautrix-signal = {
    enable = true;
    settings = {
      homeserver.address = "http://localhost:8008";
      appservice = {
        hostname = "0.0.0.0";
        port = 29328;
        database.type = "sqlite3";
      };
      bridge.permissions."*" = "relay";
      signal.socket_path = "/var/run/signald/signald.sock";
    };
  };

  services.mautrix-whatsapp = {
    enable = true;
    settings = {
      homeserver.address = "http://localhost:8008";
      appservice = {
        hostname = "0.0.0.0";
        port = 29329;
        database.type = "sqlite3";
      };
      bridge.permissions."*" = "relay";
    };
  };

  services.nix-serve = {
    enable = true;
    bindAddress = "0.0.0.0";
    port = 5000;
  };

  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8082;
    openFirewall = true;
  };

  services.owncast = {
    enable = true;
    listen = "0.0.0.0";
    port = 8083;
    openFirewall = true;
  };

  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    port = 28981;
    settings.PAPERLESS_URL = "http://paperless.example.com";
  };

  services.redlib = {
    enable = true;
    address = "0.0.0.0";
    port = 8084;
    openFirewall = true;
  };

  services.tabby = {
    enable = true;
    host = "0.0.0.0";
    port = 8085;
  };

  services.zipline = {
    enable = true;
    settings = {
      CORE_HOSTNAME = "0.0.0.0";
      CORE_PORT = 3002;
      CORE_SECRET = "dummy-secret-32-chars-long-xxxxx";
    };
  };

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    secretsFile = null;
  };

  services.coder = {
    enable = true;
    listenAddress = "0.0.0.0:3003";
    accessUrl = "http://coder.example.com";
  };

  services.prometheus = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9090;
  };

  services.anki-sync-server = {
    enable = true;
    address = "0.0.0.0";
    port = 27701;
    openFirewall = true;
    users = [
      {
        username = "testuser";
        password = "testpass";
      }
    ];
  };

  services.atuin = {
    enable = true;
    host = "0.0.0.0";
    port = 8888;
    openFirewall = true;
  };

  services.glance = {
    enable = true;
    openFirewall = true;
    settings.server = {
      host = "0.0.0.0";
      port = 8086;
    };
  };

  services.jellyseerr = {
    enable = true;
    port = 5055;
    openFirewall = true;
  };

  services.komga = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8087;
  };

  services.lidarr = {
    enable = true;
    openFirewall = true;
  };

  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
    };
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
  };

  services.scrutiny = {
    enable = true;
    openFirewall = true;
    settings.web.listen = {
      host = "0.0.0.0";
      port = 8088;
    };
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  services.step-ca = {
    enable = true;
    address = "0.0.0.0";
    port = 8443;
    openFirewall = true;
    intermediatePasswordFile = "/var/lib/step-ca/intermediate_password";
    settings = {
      root = dummyCert;
      crt = dummyCert;
      key = dummyPrivateKey;
      dnsNames = [ "ca.example.com" ];
      db = {
        type = "badger";
        dataSource = "/var/lib/step-ca/db";
      };
      authority.provisioners = [ ];
    };
  };

  services.forgejo = {
    enable = true;
    settings = {
      DEFAULT.APP_NAME = "Test Forgejo";
      server = {
        ROOT_URL = "http://forgejo.example.com";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3004;
      };
    };
  };

  services.gitea = {
    enable = true;
    settings = {
      DEFAULT.APP_NAME = "Test Gitea";
      server = {
        ROOT_URL = "http://gitea.example.com";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3005;
      };
    };
  };

  services.grafana = {
    enable = true;
    settings.server = {
      root_url = "http://grafana.example.com";
      http_addr = "0.0.0.0";
      http_port = 3006;
    };
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = 3100;
      };
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/var/lib/loki";
      };
      schema_config.configs = [
        {
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config.filesystem.directory = "/var/lib/loki/chunks";
    };
  };

  services.searx = {
    enable = true;
    settings = {
      server = {
        bind_address = "0.0.0.0";
        port = 8089;
        secret_key = "dummy-secret-key";
      };
    };
  };

  services.kavita = {
    enable = true;
    settings.Port = 5001;
    tokenKeyFile = dummySecretKey;
  };

  services.influxdb2 = {
    enable = true;
    settings.http-bind-address = "0.0.0.0:8086";
  };

  services.firefox-syncserver = {
    enable = true;
    singleNode = {
      enable = true;
      url = "http://firefox-sync.example.com";
      hostname = "firefox-sync.example.com";
    };
    secrets = dummySecret;
    settings = {
      host = "0.0.0.0";
      port = 5002;
    };
  };

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "0.0.0.0:5232" ];
      auth.type = "none";
    };
  };

  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = dummySecret;
      storageEncryptionKeyFile = dummySecretKey;
    };
    settings = {
      theme = "light";
      server.address = "tcp://0.0.0.0:9091";
      authentication_backend.file.path = "/var/lib/authelia-main/users.yml";
      storage.local.path = "/var/lib/authelia-main/db.sqlite3";
      access_control.default_policy = "deny";
      session.domain = "example.com";
      notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";
    };
  };

  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = 5353;
        http = 4000;
      };
      upstreams.groups.default = [ "1.1.1.1" ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."example.com".extraConfig = ''
      reverse_proxy localhost:8080 {
      }
    '';
  };

  services.dnsmasq = {
    enable = true;
    settings.address = [ "/example.com/192.168.1.1" ];
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "0.0.0.0";
        port = 1883;
        users = { };
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."nginx.example.com" = {
      locations."/" = {
        proxyPass = "http://localhost:8080";
      };
    };
  };

  services.traefik = {
    enable = true;
    dynamicConfigOptions = {
      http = {
        routers.test-router = {
          rule = "Host(`test.example.com`)";
          service = "test-service";
        };
        services.test-service.loadBalancer.servers = [ { url = "http://localhost:8080"; } ];
      };
    };
  };

  services.hickory-dns = {
    enable = true;
    settings = {
      listen_addrs_ipv4 = [ "0.0.0.0" ];
      listen_addrs_ipv6 = [ "::" ];
      listen_port = 8053;
      zones = [ ];
    };
  };

  services.home-assistant = {
    enable = true;
    config = {
      homeassistant = {
        name = "Test Home";
        unit_system = "metric";
        time_zone = "UTC";
      };
      http = {
        server_host = [ "0.0.0.0" ];
        server_port = 8123;
      };
    };
  };

  services.hydra = {
    enable = true;
    hydraURL = "http://hydra.example.com";
    listenHost = "0.0.0.0";
    port = 3007;
    notificationSender = "hydra@example.com";
  };

  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidm_1_8;
    serverSettings = {
      origin = "https://kanidm.example.com";
      bindaddress = "0.0.0.0:8443";
      domain = "kanidm.example.com";
      tls_chain = "/var/lib/kanidm/chain.pem";
      tls_key = "/var/lib/kanidm/key.pem";
    };
  };

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = "matrix.example.com";
      public_baseurl = "https://matrix.example.com";
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "0.0.0.0" ];
          type = "http";
          tls = false;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
      ];
    };
  };

  services.mpd = {
    enable = true;
    settings.music_directory = "/var/lib/mpd/music";
  };

  services.plausible = {
    enable = true;
    server = {
      baseUrl = "http://plausible.example.com";
      listenAddress = "0.0.0.0";
      port = 8000;
      secretKeybaseFile = dummySecret;
    };
  };

  services.static-web-server = {
    enable = true;
    listen = "[::]:8787";
    root = "/var/www";
  };

  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_HOST = "0.0.0.0";
      SERVER_PORT = "8088";
    };
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
    };
  };

  services.vaultwarden = {
    enable = true;
    config = {
      rocketAddress = "0.0.0.0";
      rocketPort = 8012;
      domain = "https://vault.example.com";
    };
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      permit_join = false;
      mqtt.server = "mqtt://localhost:1883";
      serial.port = "/dev/null";
      frontend = {
        host = "0.0.0.0";
        port = 8092;
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "nextcloud.example.com";
    https = true;
    config = {
      adminpassFile = null;
      adminuser = null;
      dbtype = "sqlite";
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.oauth2-proxy = {
    enable = true;
    httpAddress = "http://0.0.0.0:4180";
    cookie.secret = "0123456789abcdef0123456789abcdef";
    clientID = "test-client-id";
    clientSecret = "test-client-secret";
    provider = "google";
    email.domains = [ "*" ];
    keyFile = dummySecret;
  };

  services.samba = {
    enable = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "Test Samba";
      };
      public = {
        path = "/srv/public";
        browseable = "yes";
        "read only" = "no";
      };
    };
  };
}
