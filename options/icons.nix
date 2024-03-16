f: {
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    filterAttrs
    init
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

  mkIcons = name:
    mkOption {
      description = "Defines icons for ${name}.";
      default = {};
      type = types.attrsOf iconType;
    };
in
  f {
    options.icons = {
      interfaces = mkIcons "network interface types";
      services = mkIcons "services";
    };

    config.icons = {
      interfaces = iconsFromFiles ../icons/interfaces;
      services = iconsFromFiles ../icons/services;
    };
  }
