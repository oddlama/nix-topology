_: {
  name = "I2P";
  icon = "services.i2p";
  nixos = {
    path = "services.i2pd";
  };
  oci.repos = [ "i2pd" ];
  test = {
    config = {
      services.i2pd = {
        enable = true;
      };
    };
    expect = {
      name = "I2P";
    };
  };
}
