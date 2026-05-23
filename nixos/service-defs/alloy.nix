_: {
  name = "Alloy";
  icon = "services.alloy";
  nixos = {
    path = "services.alloy";
    detailsFn = _: { };
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
