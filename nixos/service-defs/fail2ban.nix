_: {
  name = "Fail2Ban";
  icon = "services.fail2ban";
  nixos = {
    path = "services.fail2ban";
    detailsFn = _: { };
  };
  test = {
    config = {
      services.fail2ban.enable = true;
    };
    expect = {
      name = "Fail2Ban";
    };
  };
}
