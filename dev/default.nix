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
    let
      inherit (pkgs) lib;
      pkgsStable = import inputs.nixpkgs-stable {
        inherit system;
        overlays = [ self.overlays.default ];
      };
      mkServiceDefChecks =
        { suffix, testPkgs }:
        lib.mapAttrs'
          (name: value: {
            name = "${name}${suffix}";
            inherit value;
          })
          (
            import ./service-def-tests.nix {
              inherit self system;
              pkgs = testPkgs;
            }
          );
    in
    {
      checks = lib.optionalAttrs (lib.hasSuffix "-linux" system) (
        {
          service-extraction = import ./service-extraction-test.nix { inherit self pkgs system; };
          service-registry-override = import ./service-registry-override-test.nix {
            inherit self pkgs system;
          };
          svg-render = import ./svg-render-test.nix { inherit self pkgs system; };
        }
        // mkServiceDefChecks {
          suffix = "";
          testPkgs = pkgs;
        }
        // mkServiceDefChecks {
          suffix = "-stable";
          testPkgs = pkgsStable;
        }
      );
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
            package = pkgs.prettier;
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
    };
}
