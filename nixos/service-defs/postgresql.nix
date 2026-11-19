{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "PostgreSQL";
  icon = "services.postgresql";
  nixos = {
    path = "services.postgresql";
    detailsFn = { cfg, ... }: {
      listen = mkIf (cfg.enableTCPIP or false) { text = "0.0.0.0:${toString cfg.settings.port}"; };
    };
  };
  oci.repos = [
    "postgres"
    "postgresql"
    "postgis"
    "pgvector"
    "pgvecto-rs"
    "vchord-postgres"
    "cloudnative-vectorchord"
    "timescaledb"
    "timescaledb-ha"
  ];
  test = {
    config = {
      services.postgresql = {
        enable = true;
        enableTCPIP = true;
        settings.port = 5432;
      };
    };
    expect = {
      name = "PostgreSQL";
      details.listen = "0.0.0.0:5432";
    };
  };
}
