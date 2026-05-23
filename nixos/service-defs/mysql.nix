{ lib }:
let
  isMariadb =
    cfg:
    let
      r = builtins.tryEval (lib.getName cfg.package);
    in
    r.success && r.value == "mariadb-server";
in
{
  name = "MySQL";
  icon = "services.mysql";
  nixos = {
    path = "services.mysql";
    nameFn = cfg: if isMariadb cfg then "MariaDB" else "MySQL";
    iconFn = cfg: if isMariadb cfg then "services.mariadb" else "services.mysql";
    detailsFn = _: { };
  };
}
