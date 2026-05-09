{
  inputs.ix-images.url = "github:indexable-inc/images";

  outputs =
    { ix-images, ... }:
    let
      ix = ix-images;
      fleet = import ./default.nix { inherit ix; };
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    {
      apps = builtins.listToAttrs (
        map (system: {
          name = system;
          value = {
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
        }) systems
      );

      packages = builtins.listToAttrs (
        map (system: {
          name = system;
          value = fleet.packages // {
            inherit (fleet) command switch;
          };
        }) systems
      );
    };
}
