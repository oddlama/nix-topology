_: {
  name = "Karakeep";
  icon = "services.karakeep";
  nixos = {
    path = "services.karakeep";
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
