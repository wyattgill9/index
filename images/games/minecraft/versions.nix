# Versioned overlays for the minecraft image.
#
# Discovery exposes `minecraft_<key>` for every version key and `minecraft` as
# an alias for the version named in `default`.
#
# Per-variant mods come from generated JSON files in ./mods/<game-version>.json
# (produced by tools/update-mods.py). Cross-version baseline mods are in
# ./mods/common.json, consumed by the image base (./default.nix).
{ lib, ... }:
let
  default = "26w17a-fabric";

  modsFor = ver: builtins.fromJSON (builtins.readFile ./mods/${ver}.json);

  variants = {
    "26w17a-fabric" = {
      loader = "fabric";
      minecraftVersion = "26.2-snapshot-5";
      loaderVersion = "0.19.2";
      installerVersion = "1.1.1";
      hash = "sha256-IZctWQu9VH4Z5lU/VcEzvPGLfW8boOAXtCaQlKXyA5k=";
      gameVersion = "26.2-snapshot-5";
    };

    "26.1.2-fabric" = {
      loader = "fabric";
      minecraftVersion = "26.1.2";
      loaderVersion = "0.19.2";
      installerVersion = "1.1.1";
      hash = "sha256-6RvRm5/w4ExXhD5iTS9U0KPjmgSMr8pejiDrmENEXb0=";
      gameVersion = "26.1.2";
    };
  };

  mkVariant =
    tag:
    {
      loader,
      gameVersion,
      ...
    }@cfg:
    { pkgs, ... }:
    {
      ix.image.tag = tag;
      services.minecraft.${loader} = (builtins.removeAttrs cfg [ "loader" "gameVersion" ]) // {
        enable = true;
      };
      services.minecraft.mods = map pkgs.fetchurl (modsFor gameVersion);
    };
in
{
  inherit default;
}
// lib.mapAttrs mkVariant variants
