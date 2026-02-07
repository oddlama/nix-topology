{ inputs, self, ... }:
{
  imports = with inputs; [
    git-hooks-nix.flakeModule
    treefmt-nix.flakeModule
  ];

  perSystem =
    {
      config,
      system,
      pkgs,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };

      treefmt = {
        flakeCheck = false; # Already covered by git-hooks
        settings.formatter."svg-optimizer" = {
          includes = [ "*.svg" ];
          excludes = [ "icons/services/mpd.svg" ];
          command = pkgs.writeShellApplication {
            name = "svg-optimizer";
            runtimeInputs = with pkgs; [
              scour
              svgo
            ];
            text = ''
              for file in "$@"; do
                # Save original timestamp
                ts="$(stat -c %y "$file")"

                tmp="$(mktemp)"

                scour --enable-viewboxing -i "$file" -o "$tmp"
                svgo --multipass -i "$tmp" -o "$tmp"

                if ! cmp -s "$file" "$tmp"; then
                  mv "$tmp" "$file"
                else
                  rm "$tmp"
                fi

                # Restore timestamp
                touch -d "$ts" "$file"
              done
            '';
          };
        };
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
          excludes = [ "mpd\\.svg" ];
          packageOverrides.treefmt = config.treefmt.build.wrapper;
          pass_filenames = true;
        };
      };

      devShells.default = config.pre-commit.devShell;

      checks = inputs.nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
        service-defs =
          let
            checkPkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
              config.allowUnfree = true;
            };

            nixos = inputs.nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                self.nixosModules.default
                ../tests/service-defs/test-module.nix
              ];
            };

            topology = import self {
              pkgs = checkPkgs;
              modules = [ { nixosConfigurations.test-services = nixos; } ];
            };
          in
          checkPkgs.runCommand "check-service-defs"
            {
              topologyOutput = topology.config.output;
              nixosToplevel = nixos.config.system.build.toplevel;
            }
            ''
              echo "Topology output: $topologyOutput"
              ls -la "$topologyOutput"
              touch $out
            '';
      };
    };
}
