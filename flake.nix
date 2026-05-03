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

      templates.default = {
        path = ./template;
        description = "Starter ix image";
      };
    };
}
