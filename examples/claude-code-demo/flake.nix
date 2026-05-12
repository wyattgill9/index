{
  inputs = {
    artifact-minecraft-server-26-2-snapshot-6-fabric = {
      url = "https://meta.fabricmc.net/v2/versions/loader/26.2-snapshot-6/0.19.2/1.1.1/server/jar";
      flake = false;
    };
    index.url = "github:indexable-inc/index";
  };

  outputs =
    {
      artifact-minecraft-server-26-2-snapshot-6-fabric,
      index,
      ...
    }:
    let
      ix = index;
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forSystems = f: builtins.listToAttrs (map f systems);
      fleetFor =
        hostSystem:
        import ./default.nix {
          inherit ix hostSystem;
          minecraftServer = artifact-minecraft-server-26-2-snapshot-6-fabric;
        };
    in
    {
      apps = forSystems (
        system:
        let
          fleet = fleetFor system;
        in
        {
          name = system;
          value = {
            switch = {
              type = "app";
              program = "${fleet.switch}/bin/ix-fleet-switch";
            };

            plan = {
              type = "app";
              program = "${fleet.planCommand}/bin/ix-fleet-plan";
            };

            diff = {
              type = "app";
              program = "${fleet.diff}/bin/ix-fleet-diff";
            };

            replace = {
              type = "app";
              program = "${fleet.replace}/bin/ix-fleet-replace";
            };
          };
        }
      );

      packages = forSystems (
        system:
        let
          fleet = fleetFor system;
        in
        {
          name = system;
          value =
            fleet.packages
            // fleet.systemPackages
            // {
              inherit (fleet)
                command
                diff
                planCommand
                replace
                switch
                ;
            };
        }
      );
    };
}
