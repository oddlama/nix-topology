f: {
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    filterAttrs
    getAttrFromPath
    hasAttrByPath
    hasPrefix
    init
    mapAttrs
    mapAttrs'
    mkOption
    nameValuePair
    splitString
    types
    ;

  removeExtension = filename: concatStringsSep "." (init (splitString "." filename));

  iconsFromFiles = dir:
    mapAttrs' (file: _: nameValuePair (removeExtension file) {file = dir + "/${file}";}) (
      filterAttrs (_: type: type == "regular") (builtins.readDir dir)
    );

  iconType = types.submodule {
    options = {
      file = mkOption {
        description = "The icon file";
        type = types.path;
      };
    };
  };
in
  f {
    options.icons = mkOption {
      description = "All predefined icons by category.";
      default = {};
      type = types.attrsOf (types.attrsOf iconType);
    };

    config = {
      # The necessary assertion for an icon type
      lib.assertions.iconValid = icon: path: {
        assertion = icon != null -> (!hasPrefix "/" icon -> hasAttrByPath (splitString "." icon) config.icons);
        message = "topology: ${path} refers to an unknown icon icons.${icon}";
      };

      # The function that returns the image path for an icon option
      lib.icons.get = icon: let
        attrPath = splitString "." icon;
      in
        if icon == null
        then null
        # Icon is a path
        else if hasPrefix "/" icon
        then icon
        # Icon is a valid icon name
        else if hasAttrByPath attrPath config.icons
        then (getAttrFromPath attrPath config.icons).file
        # Icon is not valid
        else throw "Reference to unknown icon ${icon} detected. Aborting.";

      icons =
        mapAttrs (n: _: iconsFromFiles ../icons/${n})
        (filterAttrs (_: v: v == "directory") (builtins.readDir ../icons));
    };
  }
