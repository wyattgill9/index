# Versioned overlays for the minecraft image.
#
# Each top-level key (other than `default`) is a NixOS module merged on top
# of `./default.nix`. `default` names the version that gets the unsuffixed
# `minecraft` flake package; every key produces `minecraft_<key>` regardless.
#
# To add a version: pin the upstream version strings, run a build with a
# placeholder hash, and copy the SRI hash Nix prints into `serverJarHash`.
{
  default = "26w17a";

  "26w17a" = {
    ix.image.tag = "26w17a-fabric";
    services.minecraft = {
      minecraftVersion = "26.2-snapshot-5";
      fabricLoaderVersion = "0.19.2";
      fabricInstallerVersion = "1.1.1";
      serverJarHash = "sha256-IZctWQu9VH4Z5lU/VcEzvPGLfW8boOAXtCaQlKXyA5k=";
    };
  };
}
