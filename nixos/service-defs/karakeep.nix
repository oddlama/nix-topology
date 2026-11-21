_: {
  name = "Karakeep";
  icon = "services.karakeep";
  nixos = {
    path = "services.karakeep";
  };
  oci.repos = [
    "karakeep"
    "hoarder-app/hoarder"
  ];
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
