{ lib }:
let
  inherit (lib) concatStringsSep mapAttrs toList;
in
{
  name = "Stalwart";
  icon = "services.stalwart";
  nixos = {
    # `services.stalwart-mail` is renamed to this path by nixpkgs
    path = "services.stalwart";
    infoFn = { cfg, ... }: cfg.settings.server.hostname or null;
    detailsFn =
      { cfg, ... }:
      mapAttrs (_: listener: { text = concatStringsSep ", " (toList listener.bind); }) (
        cfg.settings.server.listener or { }
      );
  };
  test = {
    config = {
      services.stalwart = {
        enable = true;
        stateVersion = "26.05";
        settings.server = {
          hostname = "mail.example.com";
          listener = {
            imap = {
              bind = [ "[::]:143" ];
              protocol = "imap";
            };
            smtp = {
              bind = [
                "[::]:25"
                "[::]:587"
              ];
              protocol = "smtp";
            };
          };
        };
      };
    };
    # The module requires `stateVersion`, and reading its settings needs it
    minimalConfig = {
      services.stalwart = {
        enable = true;
        stateVersion = "26.05";
      };
    };
    expect = {
      name = "Stalwart";
      info = "mail.example.com";
      details = {
        imap = "[::]:143";
        smtp = "[::]:25, [::]:587";
      };
    };
  };
}
