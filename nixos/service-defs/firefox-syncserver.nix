{ lib }:
let
  # `database.type` is required on newer nixpkgs and doesn't exist on older ones
  databaseType =
    { options, ... }:
    {
      services.firefox-syncserver = lib.optionalAttrs (
        options.services.firefox-syncserver.database ? type
      ) { database.type = "postgresql"; };
    };
in
{
  name = "Firefox Syncserver";
  icon = "services.firefox-syncserver";
  nixos = {
    path = "services.firefox-syncserver";
    infoFn = cfg: if cfg.singleNode.enable or false then cfg.singleNode.url else null;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.settings.host or "127.0.0.1"}:${toString cfg.settings.port}";
      };
    };
  };
  test = {
    config = {
      imports = [ databaseType ];
      services.firefox-syncserver = {
        enable = true;
        singleNode = {
          enable = true;
          url = "https://sync.example.com";
          hostname = "localhost";
        };
        secrets.master-password = "/dev/null";
        settings = {
          host = "0.0.0.0";
          port = 5000;
          database_url = "postgresql:///syncstorage";
        };
      };
    };
    expect = {
      name = "Firefox Syncserver";
      info = "https://sync.example.com";
      details.listen = "0.0.0.0:5000";
    };
  };
}
