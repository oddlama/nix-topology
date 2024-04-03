# 🖇️ Networks

By defining networks you can have connections within this network rendered in a common style/color.
This will also cause the network connections to appear in the logical network-centric view.

You only need to assign a network to one interface and it will
automatically be propagated through its connections and any switches/routers on the path.
Networks will even automatically use a predefined styles that isn't used by any other network,
unless you override it.

To create a network, give it a name and optionally some information about the covered
ipv4/ipv6 address space. Then assign it to any participating interface:

```nix
{
  networks.home = {
    name = "Home Network";
    cidrv4 = "192.168.1.1/24";
  };
  nodes.myhost.interfaces.lan1.network = "home";
}
```

Some extractors (such as the kea extractor) can create networks automatically, so all you need
to do there is to assign a friendly name.

## Style

All connections in a network can be styled by setting the style attribute on the network.
You can have solid, dashed or dotted connections with one or two colors:

```nix
{
  networks.home.style = {
    primaryColor = "#70a5eb";
    secondaryColor = null; # only relevant for dashed and dotted, null means transparent background
    pattern = "solid"; # one of "solid", "dashed", "dotted"
  };
}
```
