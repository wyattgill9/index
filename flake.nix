{
  description = "Pre-built OCI images for ix VMs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      ix = import ./lib { inherit nixpkgs; };
    in
    {
      lib = ix;
      modules = import ./modules;

      packages.${ix.system} = ix.discoverImages ./images;
      checks.${ix.system}.eval = import ./tests { inherit nixpkgs ix; };
      formatter.${ix.system} = nixpkgs.legacyPackages.${ix.system}.nixfmt;

      templates.default = {
        path = ./template;
        description = "Starter ix image";
      };
    };
}
