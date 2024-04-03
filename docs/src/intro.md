# Intro

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

## ❤️ Contributing

Contributions are whole-heartedly welcome! Please feel free to suggest new features,
implement extractors, other stuff, or generally help out if you'd like. We'd be happy to have you.

## 📜 License

Licensed under the MIT license ([LICENSE](https://github.com/oddlama/nix-topology/LICENSE) or <https://opensource.org/licenses/MIT>).
Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in this project by you, shall be licensed as above, without any additional terms or conditions.
