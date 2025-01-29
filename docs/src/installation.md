# 📦 Installation

Installation should be as simple as adding nix-topology to your flake.nix,
defining the global module and adding the NixOS module to your systems:

1. Add nix-topology as an input to your flake
   ```nix
   inputs.nix-topology.url = "github:oddlama/nix-topology";
   ```
2. Add the exposed overlay to your global pkgs definition, so the necessary tools are available for rendering
   ```nix
   pkgs = import nixpkgs {
     inherit system;
     overlays = [nix-topology.overlays.default];
   };
   ```
3. Import the exposed NixOS module `nix-topology.nixosModules.default` in your host configs
   ```nix
   nixosConfigurations.host1 = lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./host1/configuration.nix
        nix-topology.nixosModules.default
      ];
   };
   ```
4. Create the global topology by using `topology = import nix-topology { pkgs = /*...*/; };`.
   Expose this as an output in your flake so you can access it.
   ```nix
   inputs.nix-topology.url = "github:oddlama/nix-topology";
   topology = import nix-topology {
     inherit pkgs; # Only this package set must include nix-topology.overlays.default
     modules = [
       # Your own file to define global topology. Works in principle like a nixos module but uses different options.
       ./topology.nix
       # Inline module to inform topology of your existing NixOS hosts.
       { nixosConfigurations = self.nixosConfigurations; }
     ];
   };
   ```
5. Render your topology via `nix build .#topology.<current-system>.config.output`, the resulting directory will contain your finished svgs.
   Note that this can take a minute, depending on how many hosts you have defined. Evaluating many nixos configurations just takes some time,
   and the renderer sometimes struggles with handling bigger PNGs in a timely fashion.

<details>
<summary>Example flake.nix</summary>

```nix
{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, nixpkgs, nix-topology, ... }: {
    # Example. Use your own hosts and add the module to them
    nixosConfigurations.host1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./host1/configuration.nix
        nix-topology.nixosModules.default
      ];
    };
  }
  // flake-utils.lib.eachDefaultSystem (system: rec {
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ nix-topology.overlays.default ];
    };

    topology = import nix-topology {
      inherit pkgs;
      modules = [
        # Your own file to define global topology. Works in principle like a nixos module but uses different options.
        ./topology.nix
        # Inline module to inform topology of your existing NixOS hosts.
        { nixosConfigurations = self.nixosConfigurations; }
      ];
    };
  });
}
```

</details>
