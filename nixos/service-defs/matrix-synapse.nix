{ lib }:
let
  inherit (lib) head mkIf;
in
{
  name = "Matrix (Synapse)";
  icon = "services.matrix";
  nixos = {
    path = [
      "services"
      "matrix-synapse"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: cfg.settings.public_baseurl;
    detailsFn =
      cfg:
      let
        listener = head (cfg.settings.listeners or [ ]);
      in
      mkIf (listener != null) {
        listen = {
          text = "${head listener.bind_addresses}:${toString listener.port}";
        };
      };
  };
  test = {
    config = {
      services.matrix-synapse = {
        enable = true;
        settings = {
          server_name = "example.com";
          public_baseurl = "https://matrix.example.com";
          listeners = [
            {
              bind_addresses = [ "0.0.0.0" ];
              port = 8008;
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = [ "client" ];
                  compress = true;
                }
              ];
            }
          ];
        };
      };
    };
    assertions = services: [
      {
        assertion = services.matrix-synapse.name == "Matrix (Synapse)";
        message = "expected name 'Matrix (Synapse)', got '${services.matrix-synapse.name}'";
      }
      {
        assertion = services.matrix-synapse.info == "https://matrix.example.com";
        message = "expected info 'https://matrix.example.com', got '${services.matrix-synapse.info}'";
      }
      {
        assertion = services.matrix-synapse.details.listen.text == "0.0.0.0:8008";
        message = "expected listen '0.0.0.0:8008', got '${services.matrix-synapse.details.listen.text}'";
      }
    ];
  };
}
