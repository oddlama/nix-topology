{ lib }:
let
  inherit (lib) map toList;
in
{
  name = "Home Assistant";
  icon = "services.home-assistant";
  nixos = {
    path = "services.home-assistant";
    # `config` is null when configuration.yaml is managed outside of nix. Newer nixpkgs
    # don't default http.server_host/server_port, so use Home Assistant's own defaults.
    detailsFn =
      cfg:
      if cfg.config == null then
        { }
      else
        let
          http = cfg.config.http or { };
          port = toString (http.server_port or 8123);
          hosts = toList (
            http.server_host or [
              "0.0.0.0"
              "::"
            ]
          );
        in
        {
          listen = {
            text = toString (map (addr: "${addr}:${port}") hosts);
          };
        };
  };
  test = {
    config = {
      services.home-assistant = {
        enable = true;
        config.http = {
          server_host = [
            "0.0.0.0"
            "::0"
          ];
          server_port = 8123;
        };
      };
    };
    expect = {
      name = "Home Assistant";
      details.listen = "0.0.0.0:8123 ::0:8123";
    };
  };
}
