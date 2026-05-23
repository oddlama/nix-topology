_: {
  name = "Karakeep";
  icon = "services.karakeep";
  nixos = {
    path = "services.karakeep";
    detailsFn = _: { };
  };
  test = {
    config = {
      services.karakeep = {
        enable = true;
      };
    };
    expect = {
      name = "Karakeep";
    };
  };
}
