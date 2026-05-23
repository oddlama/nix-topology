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
    path = "services.samba";
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
    expect = {
      name = "Samba";
      details.shares = "documents\nmedia\n";
    };
  };
}
