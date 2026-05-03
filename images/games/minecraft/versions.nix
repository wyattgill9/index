# Versioned overlays for the minecraft image.
#
# Discovery exposes `minecraft_<key>` for every version key and `minecraft` as
# an alias for the version named in `default`.
{ lib, ... }:
let
  default = "26w17a-fabric";

  variants = {
    "26w17a-fabric" = {
      loader = "fabric";
      minecraftVersion = "26.2-snapshot-5";
      loaderVersion = "0.19.2";
      installerVersion = "1.1.1";
      hash = "sha256-IZctWQu9VH4Z5lU/VcEzvPGLfW8boOAXtCaQlKXyA5k=";
    };
  };

  mkVariant =
    tag:
    { loader, ... }@cfg:
    let
      loaderOptions = builtins.removeAttrs cfg [ "loader" ];
    in
    {
      ix.image.tag = tag;
      services.minecraft.${loader} = loaderOptions // {
        enable = true;
      };
    };
in
{
  inherit default;
}
// lib.mapAttrs mkVariant variants
