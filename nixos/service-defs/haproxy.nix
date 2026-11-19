_: {
  name = "HAProxy";
  icon = "services.haproxy";
  nixos = {
    path = "services.haproxy";
  };
  oci.repos = [
    "haproxy"
    "haproxytech/haproxy-alpine"
    "haproxytech/haproxy-debian"
    "haproxytech/haproxy-ubuntu"
  ];
  test = {
    config = {
      services.haproxy.enable = true;
    };
    expect = {
      name = "HAProxy";
    };
  };
}
