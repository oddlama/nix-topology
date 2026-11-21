_: {
  name = "Syncthing";
  icon = "services.syncthing";
  nixos = {
    path = "services.syncthing";
  };
  test = {
    config = {
      services.syncthing = {
        enable = true;
      };
    };
    expect = {
      name = "Syncthing";
    };
  };
}
