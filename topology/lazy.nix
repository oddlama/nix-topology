lib: let
  inherit
    (lib)
    all
    assertMsg
    isAttrs
    mkOptionType
    showOption
    types
    ;

  # Checks whether the value is a lazy value without causing
  # it's value to be evaluated
  isLazyValue = x: isAttrs x && x ? _lazyValue;
  # Constructs a lazy value holding the given value.
  lazyValue = value: {_lazyValue = value;};

  # Represents a lazy value of the given type, which
  # holds the actual value as an attrset like { _lazyValue = <actual value>; }.
  # This allows the option to be defined and filtered from a defintion
  # list without evaluating the value.
  lazyValueOf = type:
    mkOptionType rec {
      name = "lazyValueOf ${type.name}";
      inherit (type) description descriptionClass emptyValue getSubOptions getSubModules;
      check = isLazyValue;
      merge = loc: defs:
        assert assertMsg
        (all (x: type.check x._lazyValue) defs)
        "The option `${showOption loc}` is defined with a lazy value holding an invalid type";
          types.mergeOneOption loc defs;
      substSubModules = m: types.uniq (type.substSubModules m);
      functor = (types.defaultFunctor name) // {wrapped = type;};
      nestedTypes.elemType = type;
    };

  # Represents a value or lazy value of the given type that will
  # automatically be coerced to the given type when merged.
  lazyOf = type: types.coercedTo (lazyValueOf type) (x: x._lazyValue) type;
in {
  inherit isLazyValue lazyValue lazyValueOf lazyOf;
}
