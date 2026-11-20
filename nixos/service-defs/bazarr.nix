{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Bazarr";
  icon = "services.bazarr";
  nixos = {
    path = "services.bazarr";
    detailsFn =
      { cfg, ... }:
      let
        # Newer nixpkgs moved the port from `listenPort` to `settings.general.port`
        port = cfg.settings.general.port or cfg.listenPort;
      in
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.bazarr = {
        enable = true;
        openFirewall = true;
      };
    };
    expect = {
      name = "Bazarr";
      details.listen = "0.0.0.0:6767";
    };
  };
}
