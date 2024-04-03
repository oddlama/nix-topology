{
  prefix ? ["topology"],
  pkgs ? import <nixpkgs> {},
  modules ? [],
  specialArgs ? {},
}:
pkgs.lib.evalModules {
  inherit prefix;
  modules = [./topology] ++ modules;
  specialArgs =
    {
      modulesPath = builtins.toString ./topology;
      inherit pkgs;
    }
    // specialArgs;
}
