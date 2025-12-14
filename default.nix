{
  prefix ? ["topology"],
  pkgs ? import <nixpkgs> {},
  modules ? [],
  specialArgs ? {},
  class ? "topology",
}:
pkgs.lib.evalModules {
  inherit class prefix;
  modules = [./topology] ++ modules;
  specialArgs =
    {
      modulesPath = builtins.toString ./topology;
      inherit pkgs;
    }
    // specialArgs;
}
