[Documentation](TODO) \| [Installation and Usage](#-installation-and-usage) \| [Architecture](#%EF%B8%8F-architecture)

## 🗺️ nix-topology

With nix-topology you can automatically generate SVG infrastructure and network
diagrams from your NixOS configurations, similar to the diagram above.

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

nix-topology defines a node global module for your global topology. It also exposes an (optional) nixos module
which collects information from your hosts (which you proabably want to use use because that's kind of the point).
To use it, add nix-topology to your own flake.nix and use the module in your nixos system configuration.
Usage without flakes should also be possible. These are the required steps:

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
switches, routers and stuff like that. But don't worry, all of this is simple:

### 🔗 Connections

The physical connections of a node are usually not something we can know from the configuration alone.
To connect stuff together, you can define the physical connections of an interface globall like this:

```nix
{
  # Connect node1.lan -> node2.wan
  nodes.node1.interfaces.lan.physicalConnections = [{ node = "node2"; interface = "wan"; }];
}
```

Or if the node is a NixOS system, you can make use of the options exposed by the NixOS module.
This has the disadvantage that helper functions are not available.

The `topology.self` option is just an alias for `topology.nodes.<node-name>`. So in theory you can
also define global stuff from within a participating NixOS host, if you want to. Everything in `topology`
will be merged with the global topology.

```nix
{
  # Connect node1.lan -> node2.wan
  topology.self.nodes.node1.interfaces.lan.physicalConnections = [{ node = "node2"; interface = "wan"; }];
}
```

### 🖇️ Networks

To color connections that are on the same network, all you need to do is assign a network
to one of the interfaces that is part of the network. The network will automatically be propagated
through connections and switches, and a style will automatically be selected if you don't specify one.

Some extractors such as the kea extractor can do this automatically.

```nix
# This is a topology module, so use it in your global topology, or under `topology = {};` in any participating NixOS node
{
  networks.home = {
    name = "Home Network";
    cidrv4 = "192.168.1.1/24";
  };
  nodes.myhost.interfaces.lan1.network = "home";
}
```

### 🖨️ Other devices

You will probably find yourself in a situation where you want to add external devices to
the topology. You can of course just define new nodes for them manually, but there are some
helper functions that you can use to define switches, routers or when you need an image for "The Internet".

Beware that the helpers are only available in the global topology module, not in NixOS modules.
Be sure to read the [documentation](TODO) to see what's available.

```nix
{config, ...}: let
  inherit (config.lib.topology)
    mkSwitch
    mkRouter
    mkConnection
    ;
in {
  nodes.internet = mkInternet {
    connections = [mkConnection "router" "wan1"];
  };

  nodes.router = mkRouter "FritzBox" {
    # Additional info, optional
    info = "FRITZ!Box 7520";
    image = ./image-fritzbox.png;
    # Defines existing interfaces and which of them belong to the same network
    interfaceGroups = [ ["eth1" "eth2" "eth3" "eth4"] ["wan1"] ];
    # Shorthand to add connection(s), also takes a list if required.
    connections.eth1 = mkConnection "switch1" "eth1";
  };

  # mkSwitch works just like mkRouter, but uses a different device type image by default
  nodes.switch1 = mkSwitch "Switch Bedroom 1" {
    info = "D-Link DGS-105";
    image = ./image-dlink-dgs105.png;
    interfaceGroups = [["eth1" "eth2" "eth3" "eth4" "eth5"]];
  };
}
```

## ⚙️ Architecture

The architecture of nix-topology is intentionally designed in a very modular way
in order to decouple information gathering from rendering. While there currently
are two closely coupled renderers (`svg` to create information cards and `elk` to render them in a layouted diagram),
you can simply define your own renderer and it will have access to all the gathered information.

In a nutshell, you create a topology module in your own flake.nix. This is where all the information
will be gathered into and where you will have access to all of it and also to the rendered outputs.
By pointing the topology module to your NixOS systems (e.g. `nixosConfigurations`),
their information can automatically be incorporated into the global topology.

Instead of having the global topology module aggregate your system information,
we opted to create a nixos-module that has to be included on all nixos hosts. This
module then exposes a new option `topology` which reflects the layout from the global
topology module and tallows you to also add new global information (like a switch, device or connections)
from within a node. This also makes it easier to define the structural information of the
node asssigned to your nixos host, available as `topology.self`.

Each NixOS host automatically extracts information from your NixOS configuration and exposes
them in a structured format that is defined by the main topology module. For an overview
over what is available, please refer to the [available options](TODO)

## 🤬 Caveats

There definitely are some caveats. Currently we use ELK to layout the diagram, because it really
was the only option that was configurable enough to support ports, svg embeddings, orthogonal edges
and stuff like that. But due to the way the layered ELK layouter works this can create cluttered
diagrams if edges are facing the wrong way (even though they are technically undirected).
I've considered using D2 with TALA, but as of writing this, it wasn't configurable enough to be a viable option.

Due to the long round trip required to create the svg right now (nix -> html (nix) -> svg (html-to-svg) -> import from derivation (IFD) -> elk (nix) -> svg (elk-to-svg)),
we had to accept some tradeoffs like import-from-derivation and having to maintain two additional small tools to convert html and elk to svg.

## 🔨 TODO

Yep, there's still a lot that could be added or improved.

#### Information Gathering (Extractors)

- Podman / docker harvesting
- Nixos-container extractor
- networking.interfaces extractor
- Disks (from disko) + render
- Impermanence render?
- Nixos nftables firewall render?

#### General

- NAT indication
- Macvtap interface type svg with small link
- Embed font globally, try removing satori embed? I'd like to be able to select text.
- Embed svgs in svgs. Last time I tried it made some things render incorrectly.
- Make colors configurable
- The network propagator based on options.nodes cannot deal with mkMerge and mkIf stuff currently

## ❤️ Contributing

Contributions are whole-heartedly welcome! Please feel free to suggest new features,
implement extractors, other stuff, or generally help out if you'd like. We'd be happy to have you.

## 📜 License

Licensed under the MIT license ([LICENSE](LICENSE) or <https://opensource.org/licenses/MIT>).
Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in this project by you, shall be licensed as above, without any additional terms or conditions.
