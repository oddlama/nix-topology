_: {
  name = "Alloy";
  icon = "services.alloy";
  nixos = {
    path = "services.alloy";
  };
  oci.repos = [ "grafana/alloy" ];
  test = {
    config = {
      services.alloy = {
        enable = true;
      };
    };
    expect = {
      name = "Alloy";
    };
  };
}
