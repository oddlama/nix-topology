# 🖨️ Adding nodes (switches, routers, other devices)

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

## 👾 Icons

There are several icons included in nix-topology, which you can access by setting
any of the icon options to a string `"<category>.<name>"`. Have a look at the
icons folder to see what's available already. You can also add your own
icons to the registry by defining `icons.<category>.<name>`.

## 🖼️ Images

In several places you will be able to set an icon or image to be displayed
in a node's rendering. Usually you can either reference an existing icon with `"<category>.<name>"`,
or specify a path to an image instead. Currently nix-topology supports svg, png and jpeg files.
While svg is always recommended for quality, beware that a `viewBox` must be set and it
must be square, otherwise it may be streched.

To create a viewbox for any svg and optimize it, you can use `scour` and `svgo`:

```bash
nix-shell -p nodePackages.svgo scour
scour --enable-viewboxing -i in.svg -o out.svg
svgo -i in.svg -o out.svg
```
