[![](./examples/complex/main.svg)](./examples/complex/main.svg)
Click to enlarge

# 🍁 nix-topology

With nix-topology you can automatically generate infrastructure and network
diagrams as SVGs directly from your NixOS configurations, and get something similar to the diagram above.
It defines a new global module system where you can specify what nodes and networks you have.
Most of the work is done by the included NixOS module which automatically collects all the information from your hosts.

- 🌱 Extracts a lot of information automatically from your NixOS configuration:
  - 🔗 Interface information from systemd-networkd
  - 🌐 Network information from kea
  - 🍵 Known configured services
  - 💻 Supports [microvm.nix](https://github.com/astro/microvm.nix), nixos-containers
- 🗺️ Renders both a main diagram (physical connections) and a network-centric diagram
- ➡️  Automatically propagates assigned networks through your connections
- 🖨️ Allows you to add external devices like switches, routers, printers ...

Have a look at the examples on the left for some finished configurations and inspiration.

#### Why?

I became a little envious of all the manually crafted infrastructure diagrams on [r/homelab](https://www.reddit.com/r/homelab/).
But who's got time for that?! I'd rather spend a whole lot more time
to create a generator that I will use once or twice in my life 🤡👍.
Maybe it will be useful for somebody else, too.

## ❤️ Contributing

Contributions are whole-heartedly welcome! Please feel free to suggest new features,
implement extractors, other stuff, or generally help out if you'd like. We'd be happy to have you.

## 📜 License

Licensed under the MIT license ([LICENSE](https://github.com/oddlama/nix-topology/LICENSE) or <https://opensource.org/licenses/MIT>).
Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in this project by you, shall be licensed as above, without any additional terms or conditions.
