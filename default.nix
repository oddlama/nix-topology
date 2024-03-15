inputs: {
  pkgs,
  modules ? [],
}:
inputs.nixpkgs.lib.evalModules {
  prefix = ["topology"];
  modules = [./topology] ++ modules;
  specialArgs = {
    modulesPath = builtins.toString ./topology;
    inherit pkgs;
  };
}
