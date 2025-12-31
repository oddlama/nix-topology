{ inputs, self, ... }:
{
  imports = with inputs; [
    devshell.flakeModule
    git-hooks-nix.flakeModule
  ];

  perSystem =
    {
      self',
      system,
      pkgs,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          inputs.devshell.overlays.default
        ];
      };

      formatter = pkgs.nixfmt-tree;

      pre-commit = {
        check.enable = true;
        devShell = self'.devShells.default;
        settings.hooks = {
          nixfmt.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };
      };

      devshells.default = {
        name = "nix-topology";

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
