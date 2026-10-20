{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Zigbee2MQTT";
  icon = "services.zigbee2mqtt";
  nixos = {
    path = "services.zigbee2mqtt";
    detailsFn =
      cfg:
      let
        mqttServer = cfg.settings.mqtt.server or null;
        address = cfg.settings.frontend.host or null;
        port = cfg.settings.frontend.port or null;
        listen =
          if address == null then
            null
          else if port == null then
            address
          else
            "${address}:${toString port}";
      in
      {
        listen = mkIf (listen != null) { text = listen; };
        mqtt = mkIf (mqttServer != null) { text = mqttServer; };
      };
  };
  test = {
    config = {
      services.zigbee2mqtt = {
        enable = true;
        settings = {
          mqtt.server = "mqtt://localhost:1883";
          frontend = {
            host = "0.0.0.0";
            port = 8080;
          };
        };
      };
    };
    expect = {
      name = "Zigbee2MQTT";
      details.listen = "0.0.0.0:8080";
      details.mqtt = "mqtt://localhost:1883";
    };
  };
}
