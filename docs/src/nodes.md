# 🖨️ Adding nodes or external devices

Adding new nodes is in principle very simple. All you need to do
is assign an id and (arbitrary) `deviceType`. Based on the `deviceType`
this may pre-select some configuration options such as the rendering style.

```nix
{
  nodes.toaster = {
    deviceType = "device";
    hardware.info = "ToasterMAX 3000";
  };
}
```

Nodes have many options, so be sure to read through the option reference
if you want to manually add something more complex.
