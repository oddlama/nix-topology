_: {
  name = "Alloy";
  icon = "services.alloy";
  nixos = {
    path = "services.alloy";
  };
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
