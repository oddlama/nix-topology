{pkgs}: {
  default = pkgs.devshell.mkShell {
    name = "nix-topology";

    commands = [
      {
        package = pkgs.alejandra;
        category = "formatters";
      }
      {
        package = pkgs.deadnix;
        category = "linters";
      }
      {
        package = pkgs.statix;
        category = "linters";
      }
    ];
  };
}
