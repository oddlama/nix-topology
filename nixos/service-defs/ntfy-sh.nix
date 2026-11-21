{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "ntfy";
  icon = "services.ntfy-sh";
  nixos = {
    path = "services.ntfy-sh";
    infoFn = { cfg, ... }: cfg.settings.base-url;
    detailsFn =
      { cfg, ... }:
      let
        listen = cfg.settings.listen-http or null;
      in
      {
        listen = mkIf (listen != null) { text = listen; };
      };
  };
  test = {
    config = {
      services.ntfy-sh = {
        enable = true;
        settings = {
          base-url = "https://ntfy.example.com";
          listen-http = "127.0.0.1:2586";
        };
      };
    };
    # The module requires `base-url`
    minimalConfig = {
      services.ntfy-sh = {
        enable = true;
        settings.base-url = "https://ntfy.example.com";
      };
    };
    expect = {
      name = "ntfy";
      info = "https://ntfy.example.com";
      details.listen = "127.0.0.1:2586";
    };
  };
}
