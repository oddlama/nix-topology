{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Restic backup";
  icon = "services.restic";
  nixos = {
    path = "services.restic.backups";
    instances = true;
    # Backups don't have an enable option
    enabled = _: true;
    nameFn = { instance, ... }: "Restic backup '${instance}'";
    infoFn = { cfg, ... }: mkIf (cfg.repository != null) cfg.repository;
    detailsFn = { cfg, ... }: {
      paths = {
        text = toString cfg.paths;
      };
    };
  };
  test = {
    instance = "home";
    config = {
      services.restic.backups = {
        home = {
          repository = "/mnt/backup/home";
          passwordFile = "/run/secrets/restic";
          paths = [
            "/home"
            "/var/lib"
          ];
        };
        # Only the repository file is known
        offsite = {
          repositoryFile = "/run/secrets/restic-repository";
          passwordFile = "/run/secrets/restic";
          paths = [ "/srv" ];
        };
      };
    };
    expect = {
      name = "Restic backup 'home'";
      info = "/mnt/backup/home";
      details.paths = "/home /var/lib";
    };
    assertions = services: [
      {
        assertion =
          services ? restic-backup-offsite
          && services.restic-backup-offsite.info == ""
          && services.restic-backup-offsite.details.paths.text == "/srv";
        message = "expected a second instance 'restic-backup-offsite' without info, got: ${toString (builtins.attrNames services)}";
      }
    ];
  };
}
