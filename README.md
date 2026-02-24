<p float="left">
  <a href="https://oddlama.github.io/nix-topology/examples/complex/main.svg"><img src="https://oddlama.github.io/nix-topology/examples/complex/main.svg" alt="Main view. Click to enlarge." width="45%" /></a>
  <a href="https://oddlama.github.io/nix-topology/examples/complex/network.svg"><img src="https://oddlama.github.io/nix-topology/examples/complex/network.svg" alt="Network view. Click to enlarge." width="51%" /></a>
</p>

[Documentation](https://oddlama.github.io/nix-topology) \| [Installation and Usage](#-installation-and-usage)

## 🍁 nix-topology

With nix-topology you can automatically generate infrastructure and network
diagrams as SVGs directly from your NixOS configurations, and get something similar to the diagram above.
It defines a new global module system where you can specify what nodes and networks you have.
Most of the work is done by the included NixOS module which automatically collects all the information from your hosts.

- 🌱 Extracts a lot of information automatically from your NixOS configuration:
  - 🔗 Interfaces from systemd-networkd
  - 🍵 Known configured services
  - 🖥️ Guests from [microvm.nix](https://github.com/astro/microvm.nix)
  - 🖥️ Guests from nixos containers
  - 🌐 Network information from kea
- 🗺️ Renders both a main diagram (physical connections) and a network-centric diagram
- ➡️ Automatically propagates assigned networks through your connections
- 🖨️ Allows you to add external devices like switches, routers, printers ...

Have a look at the [examples](./examples) directory for some self-contained examples
or view the rendered results in the [documentation](https://oddlama.github.io/nix-topology).

#### Why?

I became a little envious of all the manually crafted infrastructure diagrams on [r/homelab](https://www.reddit.com/r/homelab/).
But who's got time for that?! I'd rather spend a whole lot more time
to create a generator that I will use once or twice in my life 🤡👍.
Maybe it will be useful for somebody else, too.

## 📦 Installation and Usage

Installation should be as simple as adding nix-topology to your flake.nix,
defining the global module and adding the NixOS module to your systems.
A [flake-parts](https://flake.parts) module is also available (see end of this section for an example).

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
   # Repeat this for each system where you want to build your topology.
   # You can do this manually or use flake-utils.
   topology.x86_64-linux = import nix-topology {
     inherit pkgs; # Only this package set must include nix-topology.overlays.default
     modules = [
       # Your own file to define global topology. Works in principle like a nixos module but uses different options.
       ./topology.nix
       # Inline module to inform topology of your existing NixOS hosts.
       { nixosConfigurations = self.nixosConfigurations; }
     ];
   };
   ```
5. Render your topology via `nix build .#topology.x86_64-linux.config.output`, the resulting directory will contain your finished svgs.
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

<details>
<summary>Example flake.nix with flake-parts</summary>

```nix
{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nix-topology.url = "github:oddlama/nix-topology";
  # ...
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.nix-topology.flakeModule
      ];
      perSystem = {...}: {
        topology.modules = [
          {
            # Your global topology definitions
          }
        ];
      };
    };
}
```

</details>

## 🌱 Adding connections, networks and other devices

After rendering for the first time, the initial diagram might look a little unstructured.
That's simply because nix-topology will be missing some important connections that can't
be derived from a bunch of NixOS configurations, like physical connections.
You'll probably also want to add some common devices like an image for the internet,
switches, routers and stuff like that. But don't worry, all of this is quite simple.
There's a whole [chapter in the documentation](https://oddlama.github.io/nix-topology/defining-additional-things.html) that will guide you through it.

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

## 🔨 TODO

Yep, there's still a lot that could be added or improved.

#### Information Gathering (Extractors)

- networking.interfaces extractor
- Disks (from disko) + render
- Impermanence render?
- Nixos nftables firewall render?

#### General

- NAT indication
- Macvtap/vlan/bridge interface type svg with small link
- configurable font
- Make colors configurable

## ❤️ Contributing

Contributions are whole-heartedly welcome! Please feel free to suggest new features,
implement extractors, other stuff, or generally help out if you'd like. We'd be happy to have you.
There's more information in [CONTRIBUTING.md](CONTRIBUTING.md) and the [Development Chapter](./development.html) in the docs.

## 📜 License

Licensed under the MIT license ([LICENSE](LICENSE) or <https://opensource.org/licenses/MIT>).
Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in this project by you, shall be licensed as above, without any additional terms or conditions.
