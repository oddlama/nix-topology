{ inputs, self, ... }:
{
  imports = with inputs; [
    git-hooks-nix.flakeModule
    treefmt-nix.flakeModule
  ];

  perSystem =
    { config, system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };

      treefmt = {
        flakeCheck = false; # Already covered by git-hooks
        programs = {
          # PNG
          oxipng = {
            enable = true;
            opt = "max";
            strip = "safe";
          };

          # Various
          prettier = {
            enable = true;
            excludes = [
              "*package-lock.json"
              "*package.json"
            ];
          };

          # Nix
          deadnix.enable = true;
          nixfmt = {
            enable = true;
            strict = true;
          };
          statix.enable = true;

          # TOML
          taplo.enable = true;
          toml-sort.enable = true;
        };
      };

      pre-commit = {
        check.enable = true;
        settings.hooks.treefmt = {
          enable = true;
          packageOverrides.treefmt = config.treefmt.build.wrapper;
          pass_filenames = false;
        };
      };

      devShells.default = config.pre-commit.devShell;
    };
}
