{
  projectRootFile = "flake.nix";

  settings.global.excludes = ["*.svg"];

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    prettier.enable = true;

    shfmt.enable = true;

    taplo.enable = true;
    toml-sort.enable = true;
  };
}
