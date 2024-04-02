# 🔗 Connections

The physical connections of a node are usually not something we can know from the configuration alone.
To connect stuff together, you can define the physical connections of an interface globall like this:

```nix
{
  # Connect node1.lan -> node2.wan
  nodes.node1.interfaces.lan.physicalConnections = [
    { node = "node2"; interface = "wan"; }
  ];
}
```

Or by utilizing the helper:

```nix
let
  inherit (lib.topology) mkConnection;
in {
  # Connect node1.lan -> node2.wan
  nodes.node1.interfaces.lan.physicalConnections = [(mkConnection "node2" "wan")];
}
```

## Reversed connections

Sometimes it is easier to define a connection from node1.eth to node2.eth on
the "destination" node. While connections are technically undirected, the layouter
unfortunately doesn't think so. Since the layouter will try to align as many edges
in the same direction as possible with the dominant layouting order being left-to-right,
a connection going the other way can cause weird edge routing or unpleasant node locations.

By adding `renderer.reverse = true;` to the connection attrset (or by using `mkConnectionRev`),
you can change the direction of the edge.
