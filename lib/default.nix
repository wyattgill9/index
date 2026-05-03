{ nixpkgs, moduleList }:
{
  mkIxImage =
    {
      modules ? [ ],
    }:
    let
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./ix-base.nix
        ] ++ moduleList ++ modules;
      };
    in
    nixos.config.ix.build.ociImage;
}
