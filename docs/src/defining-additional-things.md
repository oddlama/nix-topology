# 🌱 Defining additional things

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

Follow through the next pages for examples on defining nodes, networks and connections.
