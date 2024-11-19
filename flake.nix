{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nci = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      fenix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.nci.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        let
          crateName = "git-cherry-branch";
          toolchain = fenix.packages.${system}.combine [
            fenix.packages.${system}.default.cargo
            fenix.packages.${system}.default.rustc
            fenix.packages.${system}.default.rustfmt
            fenix.packages.${system}.default.clippy
            fenix.packages.${system}.complete.rust-src
          ];
          crateOutputs = config.nci.outputs."git-cherry-branch";
        in
        {
          # declare projects
          # TODO: change this to your crate's path
          nci.projects.${crateName}.path = ./.;
          # configure crates
          nci.crates.${crateName} = { };
          nci.toolchains = {
            mkShell = _: toolchain;
            mkBuild = _: toolchain;
          };
          # export the crate devshell as the default devshell
          devShells.default = crateOutputs.devShell.overrideAttrs (old: {
            packages = (old.packages or [ ]) ++ [
              pkgs.nixfmt-rfc-style
              pkgs.rust-analyzer
            ];
          });
          # export the release package of the crate as default package
          packages.default = crateOutputs.packages.release;
        };
    };
}
