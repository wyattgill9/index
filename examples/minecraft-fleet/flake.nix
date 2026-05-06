{
  inputs.ix-images.url = "github:indexable-inc/images";

  outputs =
    { ix-images, ... }:
    let
      fleet = import ./default.nix { inherit ix-images; };
    in
    {
      apps.x86_64-linux = {
        switch = {
          type = "app";
          program = "${fleet.switch}/bin/ix-fleet-switch";
        };

        plan = {
          type = "app";
          program = "${fleet.command}/bin/ix-fleet";
        };

        replace = {
          type = "app";
          program = "${fleet.command}/bin/ix-fleet";
        };
      };

      packages.x86_64-linux = fleet.packages // {
        inherit (fleet) command switch;
      };
    };
}
