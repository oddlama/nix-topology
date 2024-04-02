{
  pkgs ? import <nixpkgs> {},
  modules ? [],
  specialArgs ? {},
}:
pkgs.lib.evalModules {
  prefix = ["topology"];
  modules = [./topology] ++ modules;
  specialArgs =
    {
      modulesPath = builtins.toString ./topology;
      inherit pkgs;
    }
    // specialArgs;
}
