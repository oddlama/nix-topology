_: {
  name = "BentoPDF";
  icon = "services.bentopdf";
  nixos = {
    path = [
      "services"
      "bentopdf"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: "https://${cfg.domain}";
  };
  test = {
    config = {
      services.bentopdf = {
        enable = true;
        domain = "pdf.example.com";
      };
    };
    assertions = services: [
      {
        assertion = services.bentopdf.name == "BentoPDF";
        message = "expected name 'BentoPDF', got '${services.bentopdf.name}'";
      }
      {
        assertion = services.bentopdf.info == "https://pdf.example.com";
        message = "expected info 'https://pdf.example.com', got '${services.bentopdf.info}'";
      }
    ];
  };
}
