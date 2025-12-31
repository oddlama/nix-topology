{ inputs, self, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          inputs.devshell.overlays.default
        ];
      };

      formatter = pkgs.nixfmt;

      checks.pre-commit-hooks = inputs.pre-commit-hooks.lib.${system}.run {
        src = inputs.nixpkgs.lib.cleanSource ../.;
        hooks = {
          nixfmt.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };
      };

      devShells.default = pkgs.devshell.mkShell {
        name = "nix-topology";
        devshell.startup.pre-commit.text = self.checks.${system}.pre-commit-hooks.shellHook;
        commands = [
          {
            package = pkgs.nixfmt;
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
    };
}
