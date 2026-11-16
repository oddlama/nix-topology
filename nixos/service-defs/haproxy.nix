_: {
  name = "HAProxy";
  icon = "services.haproxy";
  nixos = {
    path = "services.haproxy";
  };
  test = {
    config = {
      services.haproxy.enable = true;
    };
    expect = {
      name = "HAProxy";
    };
  };
}
