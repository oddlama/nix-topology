{ lib }:
let
  inherit (lib) forEach;
in
{
  name = "Oink";
  icon = "services.oink";
  nixos = {
    path = "services.oink";
    detailsFn = cfg: {
      domains.text = toString (
        forEach cfg.domains (
          entry: if (entry.subdomain or "") == "" then entry.domain else "${entry.subdomain}.${entry.domain}"
        )
      );
    };
  };
}
