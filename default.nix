inputs: {
  pkgs,
  modules ? [],
}:
inputs.nixpkgs.lib.evalModules {
  prefix = ["topology"];
  modules = [./modules] ++ modules;
  specialArgs = {
    modulesPath = builtins.toString ./modules;
    inherit pkgs;
  };
}
