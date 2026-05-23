{ lib }:
let
  inherit (lib)
    attrNames
    concatLines
    mkIf
    remove
    ;
in
{
  name = "Samba";
  icon = "services.samba";
  nixos = {
    path = [
      "services"
      "samba"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        shares = remove "global" (attrNames cfg.settings);
      in
      mkIf (shares != [ ]) {
        shares = {
          text = concatLines shares;
        };
      };
  };
  test = {
    config = {
      services.samba = {
        enable = true;
        settings = {
          global = { };
          media = { };
          documents = { };
        };
      };
    };
    assertions = services: [
      {
        assertion = services.samba.name == "Samba";
        message = "expected name 'Samba', got '${services.samba.name}'";
      }
      {
        assertion = services.samba.details.shares.text == "documents\nmedia\n";
        message = "expected shares 'documents\\nmedia\\n', got '${services.samba.details.shares.text}'";
      }
    ];
  };
}
