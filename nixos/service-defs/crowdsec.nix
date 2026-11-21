{ lib }:
let
  inherit (lib) mkIf;

  # The Local API settings moved from `settings.general` to `settings.config` after nixpkgs 26.05
  apiServer = cfg: cfg.settings.config.api.server or cfg.settings.general.api.server or { };
in
{
  name = "CrowdSec";
  icon = "services.crowdsec";
  nixos = {
    path = "services.crowdsec";
    detailsFn =
      { cfg, ... }:
      let
        server = apiServer cfg;
      in
      {
        listen = mkIf ((server.enable or false) && server ? listen_uri) { text = server.listen_uri; };
      };
  };
  oci.repos = [ "crowdsec" ];
  test = {
    config =
      { options, ... }:
      let
        settingsKey =
          if (options.services.crowdsec.settings.type.getSubOptions [ ]) ? config then
            "config"
          else
            "general";
      in
      {
        services.crowdsec = {
          enable = true;
          settings.${settingsKey}.api.server = {
            enable = true;
            listen_uri = "127.0.0.1:8081";
          };
        };
      };
    expect = {
      name = "CrowdSec";
      details.listen = "127.0.0.1:8081";
    };
  };
}
