# Helpers

You will probably find yourself in a situation where you want to add multiple external devices to
your topology. You can of course just define new nodes for them manually, but there are some
helper functions that you can use to quickly define switches, routers or other external devices (for example "The Internet").

These helpers are available under `config.lib.topology`, regardless of whether you are within a
topology module, or a NixOS modules.

## mkConnection & mkConnectionRev

A small helper that allows you to write `mkConection "host" "lan"` instead of
the longer form:

```nix
{ node = "host"; interface = "lan"; }
```

Also comes in a reversed variant `mkConnectionRev`, that marks the connection as reversed
to the renderer. See the chapter on connections for why this is sometimes needed.

## mkInternet

A small utility that creates a cloud image to represent the internet.
It already has an interface called `*` where you can connect stuff.
An optional parameter `connections` can take either a single connection or a list
of connections for this interface.

Example:

```nix
nodes.internet = mkInternet {
  connections = mkConnection "node1" "interface1";
};
```

## mkSwitch

This function simplifies creation of a switch. It accepts the name of
the switch as the first argument and then some optional arguments in an attrset.
It particular, it will:

- Set the device type to `switch`
- Set hardware image and info if given
- Accept a list called `interfaceGroups`. This list itself contains multiple lists of interface names.
  All interfaces are created, regardless of the list in which they appear.
  All interfaces that stand together in one list will automatically share their network with
  other interfaces in that specific list, like a dumb switch would.
- Accepts an attrset `connections` where you can specify additional connections
  for each interface in the form of a single connection or list of connections.

Example:

```nix
nodes.switch1 = mkSwitch "Switch 1" {
  info = "D-Link DGS-105";
  image = ./image-dlink-dgs105.png;
  interfaceGroups = [["eth1" "eth2" "eth3" "eth4" "eth5"]];
  connections.eth1 = mkConnection "host1" "lan";
  connections.eth2 = [(mkConnection "host2" "wan") (mkConnection "host3" "eth0")];

  # any other attributes specified here are directly forwarded to the node:
  interfaces.eth1.network = "home";
};
```

## mkRouter

Exactly the same as `mkSwitch`, but sets the device type to `router` instead of `switch`,
which changes the icon to the right.

Example:

```nix
nodes.router = mkRouter "Router" {
  info = "Some Router Type XY";
  # eth1-4 are switched, wan1 is the external DSL connection
  interfaceGroups = [["eth1" "eth2" "eth3" "eth4"] ["wan1"]];
  connections.wan1 = mkConnection "host1" "wan";
};
```

## mkDevice

Exactly the same as `mkSwitch`, but sets the device type to `device` instead of `switch`,
which has no icon to the right by default.
