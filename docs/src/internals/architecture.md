# ⚙️ Architecture

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
over what is available, please refer to the [available options](../topology-options.html)

## 🤬 Caveats

There definitely are some caveats. Currently we use ELK to layout the diagram, because it really
was the only option that was configurable enough to support ports, svg embeddings, orthogonal edges
and stuff like that. But due to the way the layered ELK layouter works this can create cluttered
diagrams if edges are facing the wrong way (even though they are technically undirected).
I've considered using D2 with TALA, but as of writing this, it wasn't configurable enough to be a viable option.

Due to the long round trip required to create the svg right now (nix -> html (nix) -> svg (html-to-svg) -> import from derivation (IFD) -> elk (nix) -> svg (elk-to-svg)),
we had to accept some tradeoffs like import-from-derivation and having to maintain two additional small tools to convert html and elk to svg.
