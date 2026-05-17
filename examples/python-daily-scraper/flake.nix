{
  inputs.index.url = "github:indexable-inc/index";

  outputs =
    { index, ... }:
    let
      fleet = import ./default.nix { inherit index; };
      package = import ./package.nix {
        ix = index.lib;
        inherit (index.lib.pkgs) lib;
      };
    in
    {
      packages.x86_64-linux = fleet.packages // {
        daily-scraper = package;
      };
    };
}
