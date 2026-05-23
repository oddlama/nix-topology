_: {
  name = "BentoPDF";
  icon = "services.bentopdf";
  nixos = {
    path = "services.bentopdf";
    infoFn = cfg: "https://${cfg.domain}";
  };
  test = {
    minimalConfig = {
      services.bentopdf = {
        enable = true;
        domain = "pdf.example.com";
      };
    };
    config = {
      services.bentopdf = {
        enable = true;
        domain = "pdf.example.com";
      };
    };
    expect = {
      name = "BentoPDF";
      info = "https://pdf.example.com";
    };
  };
}
