_: {
  name = "InfluxDB v2";
  icon = "services.influxdb2";
  nixos = {
    path = "services.influxdb2";
    detailsFn = cfg: {
      listen = {
        text = cfg.settings.http-bind-address or "localhost:8086";
      };
    };
  };
  test = {
    config = {
      services.influxdb2 = {
        enable = true;
        settings.http-bind-address = "0.0.0.0:8086";
      };
    };
    expect = {
      name = "InfluxDB v2";
      details.listen = "0.0.0.0:8086";
    };
  };
}
