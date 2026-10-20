{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "PostgreSQL";
  icon = "services.postgresql";
  nixos = {
    path = "services.postgresql";
    detailsFn = cfg: {
      listen = mkIf (cfg.enableTCPIP or false) { text = "0.0.0.0:${toString cfg.settings.port}"; };
    };
  };
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
