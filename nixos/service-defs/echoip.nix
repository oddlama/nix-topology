_: {
  name = "Echoip";
  icon = "services.not-available";
  nixos = {
    path = "services.echoip";
    detailsFn = cfg: { listen.text = cfg.listenAddress; };
  };
}
