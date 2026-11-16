{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "mautrix-meta";
  icon = "services.mautrix-meta";
  nixos = {
    path = "services.mautrix-meta.instances";
    instances = true;
    nameFn = { instance, ... }: "mautrix-meta (${instance})";
    iconFn =
      { cfg, ... }:
      if (cfg.settings.network.mode or null) == "instagram" then
        "services.mautrix-meta-instagram"
      else
        "services.mautrix-meta";
    infoFn = { cfg, ... }: cfg.settings.network.mode or null;
    detailsFn =
      { cfg, ... }:
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
  test = {
    instance = "instagram";
    config = {
      services.mautrix-meta.instances.instagram = {
        enable = true;
        settings.appservice = {
          hostname = "127.0.0.1";
          port = 29320;
        };
      };
    };
    expect = {
      name = "mautrix-meta (instagram)";
      icon = "services.mautrix-meta-instagram";
      info = "instagram";
      details.listen = "127.0.0.1:29320";
    };
    assertions = services: [
      {
        # nixpkgs predefines a disabled `facebook` instance
        assertion = !(services ? mautrix-meta-facebook);
        message = "expected the disabled 'facebook' instance to not appear";
      }
    ];
  };
}
