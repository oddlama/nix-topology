# 🌱 Adding connections, networks and other devices

After rendering for the first time, the initial diagram might look a little unstructured.
That's simply because nix-topology will be missing some important connections that can't
be derived from a bunch of NixOS configurations, like physical connections.
You'll probably also want to add some common devices like an image for the internet,
switches, routers and stuff like that.

There are two locations where you can add stuff to the topology: In the global
topology module or locally in one of the participating nixos configurations.

#### Globally

To add something in the new global topology module, simply extend the configuration
like you would with a classical NixOS module. In this example we configured
the global topology module to include definitions from `./topology.nix`:

```nix
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

So you can add things by defining one of the available node or network options in this file:

```nix
# ./topology.nix
{
  nodes.toaster = {
    name = "My Toaster";
    deviceType = "device";
  };
}
```

#### Locally

The same can be done from within any NixOS configuration that you've given
to the global module by specifying `nixosConfigurations = ...` above. All
topology options will be grouped under `topology.<...>`, so it doesn't interfere
with your NixOS configuration. All of these definitions from your NixOS hosts
and those from the global module will later be merged together.

So instead of defining the device globally, you could choose to define it in `host1`.
This makes it possible to modify the topology of other nodes from within your node,
which can be very handy:

```nix
# ./host1/configuration.nix
{
  topology.nodes.toaster = {
    name = "My Toaster";
    deviceType = "device";
  };
}
```

Since it is a very common thing to modify the node assigned to your current NixOS configuration,
there's an alias `topology.self` which aliases `topology.nodes.${config.topology.id}`:

```nix
# ./host2/configuration.nix
{
  topology.self.hardware.info = "Raspberry Pi 5";
}
```

## 🔗 Connections

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

## 🖇️ Networks

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

## 🖨️ Other devices

You will probably find yourself in a situation where you want to add external devices to
the topology. You can of course just define new nodes for them manually, but there are some
helper functions that you can use to define switches, routers or when you need an image for "The Internet".

Beware that the helpers are only available in the global topology module, not in NixOS modules.
Be sure to read the [documentation](https://oddlama.github.io/nix-topology) to see what's available.

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
