_: {
  name = "Fail2Ban";
  icon = "services.fail2ban";
  nixos = {
    path = [
      "services"
      "fail2ban"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = _: { };
  };
  test = {
    config = {
      services.fail2ban.enable = true;
    };
    assertions = services: [
      {
        assertion = services.fail2ban.name == "Fail2Ban";
        message = "expected name 'Fail2Ban', got '${services.fail2ban.name}'";
      }
    ];
  };
}
