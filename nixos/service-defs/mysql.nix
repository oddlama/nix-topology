{ lib }:
let
  isMariadb =
    cfg:
    let
      r = builtins.tryEval (lib.getName cfg.package);
    in
    r.success && r.value == "mariadb-server";
  isMariadbImage =
    { container, ... }:
    lib.hasInfix "mariadb" (lib.last (lib.splitString "/" container.image.repository));
in
{
  name = "MySQL";
  icon = "services.mysql";
  nixos = {
    path = "services.mysql";
    nameFn = { cfg, ... }: if isMariadb cfg then "MariaDB" else "MySQL";
    iconFn = { cfg, ... }: if isMariadb cfg then "services.mariadb" else "services.mysql";
  };
  oci = {
    repos = [
      "mysql"
      "mariadb"
    ];
    nameFn = args: if isMariadbImage args then "MariaDB" else "MySQL";
    iconFn = args: if isMariadbImage args then "services.mariadb" else "services.mysql";
  };
  test.oci = {
    containers = {
      mysql.image = "mysql:8.4";
      mariadb.image = "lscr.io/linuxserver/mariadb:11.4.4";
    };
    expect = {
      mysql = {
        name = "MySQL";
        icon = "services.mysql";
      };
      mariadb = {
        name = "MariaDB";
        icon = "services.mariadb";
      };
    };
  };
}
