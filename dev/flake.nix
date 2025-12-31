{
  description = ''
    Private inputs for development purposes.
    These are used by the top level flake in the `dev` partition,
    but do not appear in consumers' lock files.
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # This flake is only used for its inputs.
  outputs = _: { };
}
