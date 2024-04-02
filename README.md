[Documentation](https://oddlama.github.io/nix-topology) \| [Installation and Usage](#-installation-and-usage) \| [Architecture](#%EF%B8%8F-architecture)

## 🗺️ nix-topology

With nix-topology you can automatically generate SVG infrastructure and network
diagrams from your NixOS configurations, similar to the diagram above.
It defines a new global module system where you can specify what nodes and networks you have.
The included NixOS module can even automatically collect information from your hosts.

- 🌱 Extracts a lot of information automatically from your NixOS configuration:
  - 🔗 Interface information from systemd-networkd
  - 🌐 Network information from kea
  - 🍵 Known configured services
  - 💻 Supports [microvm.nix](https://github.com/astro/microvm.nix), nixos-containers
- 🗺️ Renders both a main diagram (physical connections) and a network-centric diagram
- ➡️  Automatically propagates assigned networks through your connections
- 🖨️ Allows you to add external devices like switches, routers, printers ...

It's really simple to add rendering support for new services. You will probably encounter
services that are not yet covered. If you'd like to help out, PRs are always welcome!

#### Why?

Well.. I became a little envious of all the manually crafted infrastructure diagrams on [r/homelab](https://www.reddit.com/r/homelab/).
But then I thought about all the time it takes to _manually draw and update_ one of these.
So I just did the next best thing: Write a generator.

## 📦 Installation and Usage

Installation should be as simple as adding nix-topology to your flake.nix,
defining the global module and adding the NixOS module to your systems:

1. Add nix-topology as an input to your flake
   ```nix
   inputs.nix-topology.url = "github:oddlama/nix-topology";
   ```
2. Add the exposed overlay to your global pkgs definition, so the necessary tools are available for rendering
3. Import the exposed NixOS module `nix-topology.nixosModules.default` in your host configs
4. Create the global topology by using `topology = import nix-topology { pkgs = /*...*/; };`.
   Expose this as an output in your flake so you can access it.
   ```nix
   inputs.nix-topology.url = "github:oddlama/nix-topology";
   topology = import nix-topology {
     inherit pkgs;
     modules = [
       # Your own file to define global topology. Works in principle like a nixos module but uses different options.
       ./topology.nix
       # Inline module to inform topology of your existing NixOS hosts.
       { nixosConfigurations = self.nixosConfigurations; }
     ];
   };
   ```
5. Render your topology via `nix build .#topology.<current-system>.config.output`, the result directory will contain your svgs.
   Note that this can be slow, depending on how many hosts you have defined. Evaluating many nixos configurations just takes some time.

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

  outputs = { self, nixpkgs, nix-topology, ... }: {
    # Example. Use your own hosts and add the module to them
    nixosConfigurations.host1 = nixpkgs.lib.nixosSystem {
      # ...
      modules = [ nix-topology.nixosModules.default ];
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

## 🌱 Adding connections, networks and other devices

After rendering for the first time, the initial diagram might look a little unstructured.
That's simply because nix-topology will be missing some important connections that can't
be derived from a bunch of NixOS configurations, like physical connections.
You'll probably also want to add some common devices like an image for the internet,
switches, routers and stuff like that. But don't worry, all of this is quite simple.
There's a whole [chapter in the documentation](https://oddlama.github.io/nix-topology/adding-additional-things.html) that will guide you through it.

TL;DR: You can add connections and networks by specifying this information
in the global topology module, or locally in one of your NixOS configs:

```nix
# This is a topology module, so use it in your global topology, or under `topology = {};` in any participating NixOS node
{
  # Connect node1.lan -> node2.wan
  nodes.node1.interfaces.lan.physicalConnections = [{ node = "node2"; interface = "wan"; }];
  # Add home network
  networks.home = {
    name = "Home Network";
    cidrv4 = "192.168.1.1/24";
  };
  # Tell nix-topology that myhost.lan1 is part of this network.
  # The network will automatically propagate via the interface's connections.
  nodes.myhost.interfaces.lan1.network = "home";
}
```

Or locally (e.g. `host1/configuration.nix`):

```nix
{
  topology.networks.home = {
    name = "Network Made by Host1";
    cidrv4 = "192.168.178.1/24";
  };
  topology.self.interfaces.lan1.network = "home";
}
```

## ❤️ Contributing

Contributions are whole-heartedly welcome! Please feel free to suggest new features,
implement extractors, other stuff, or generally help out if you'd like. We'd be happy to have you.

## 📜 License

Licensed under the MIT license ([LICENSE](LICENSE) or <https://opensource.org/licenses/MIT>).
Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in this project by you, shall be licensed as above, without any additional terms or conditions.
