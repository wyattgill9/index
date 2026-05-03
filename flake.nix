{
  description = "Pre-built OCI images for ix VMs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      ix = self.lib;

      minecraftImage = import ./images/games/minecraft;
    in
    {
      lib = import ./lib {
        inherit nixpkgs;
        moduleList = import ./modules/module-list.nix;
      };

      modules = import ./modules;

      packages.${system} = {
        kernel-dev = ix.mkIxImage { modules = [ ./images/dev/kernel-dev ]; };
        remote-desktop = ix.mkIxImage { modules = [ ./images/desktop/remote-desktop ]; };

        minecraft = self.packages.${system}.minecraft_26w17a;

        minecraft_26w17a = ix.mkIxImage {
          modules = [
            (minecraftImage {
              minecraftVersion = "26.2-snapshot-5";
              fabricLoaderVersion = "0.19.2";
              fabricInstallerVersion = "1.1.1";
              serverJarHash = "sha256-IZctWQu9VH4Z5lU/VcEzvPGLfW8boOAXtCaQlKXyA5k=";
            })
          ];
        };
      };

      templates.default = {
        path = ./template;
        description = "Starter ix image";
      };
    };
}
