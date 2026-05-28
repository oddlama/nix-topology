{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Zigbee2MQTT";
  icon = "services.zigbee2mqtt";
  nixos = {
    path = [
      "services"
      "zigbee2mqtt"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.zigbee2mqtt.name == "Zigbee2MQTT";
        message = "expected name 'Zigbee2MQTT', got '${services.zigbee2mqtt.name}'";
      }
      {
        assertion = services.zigbee2mqtt.details.listen.text == "0.0.0.0:8080";
        message = "expected listen '0.0.0.0:8080', got '${services.zigbee2mqtt.details.listen.text}'";
      }
      {
        assertion = services.zigbee2mqtt.details.mqtt.text == "mqtt://localhost:1883";
        message = "expected mqtt 'mqtt://localhost:1883', got '${services.zigbee2mqtt.details.mqtt.text}'";
      }
    ];
  };
}
