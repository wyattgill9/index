# Versioned overlays for the minecraft image.
#
# Discovery exposes `minecraft_<key>` for every version key and `minecraft` as
# an alias for the version named in `default`.
#
# Per-variant `mods` is a list of fetchurl arg attrsets ({ url, hash }).
# They are materialized into `services.minecraft.mods` and the loader picks the
# drop directory (fabric -> mods/, paper -> plugins/).
{ lib, ... }:
let
  default = "26w17a-fabric";

  # Mods that ship the same jar across multiple game versions.
  ksyxis = {
    url = "https://cdn.modrinth.com/data/2ecVyZ49/versions/kL32PN9Q/Ksyxis-1.4.3.jar";
    hash = "sha256-I8jFmTAE8FhOsnsZtDl7eqiDP0G48tHqIB7lSmD5ZLk=";
  };
  almanac = {
    url = "https://cdn.modrinth.com/data/Gi02250Z/versions/7IRzJzBP/almanac-1.26.x-fabric-1.6.2.1.jar";
    hash = "sha256-RnaTFnM1GKbL0BONw0Yn23neTG9tCq3BhJ+pYP/FQJg=";
  };
  letMeDespawn = {
    url = "https://cdn.modrinth.com/data/vE2FN5qn/versions/eW5P1rHo/letmedespawn-1.26.x-fabric-1.6.2.1.jar";
    hash = "sha256-2t/dwf8jrqNr8yei3Raf0tRb8Xs4WpYij+cJ6iFJKII=";
  };

  variants = {
    "26w17a-fabric" = {
      loader = "fabric";
      minecraftVersion = "26.2-snapshot-5";
      loaderVersion = "0.19.2";
      installerVersion = "1.1.1";
      hash = "sha256-IZctWQu9VH4Z5lU/VcEzvPGLfW8boOAXtCaQlKXyA5k=";
      mods = [
        { url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/kw0Rlte8/fabric-api-0.147.1%2B26.2.jar"; hash = "sha256-3g3blJ5SQZl+cb+GvrVFmNeItdlxOvbSCh6UDaIqmNs="; }
        { url = "https://cdn.modrinth.com/data/VSNURh3q/versions/h0G6V9wK/c2me-fabric-mc26.2-snapshot-5-0.3.7%2Balpha.0.68.jar"; hash = "sha256-aASz7sslXqYn2p1BI3ZCOUNaPXj8YDCmoUPuyj63kws="; }
        ksyxis
        almanac
        letMeDespawn
      ];
    };

    "26.1.2-fabric" = {
      loader = "fabric";
      minecraftVersion = "26.1.2";
      loaderVersion = "0.19.2";
      installerVersion = "1.1.1";
      hash = "sha256-6RvRm5/w4ExXhD5iTS9U0KPjmgSMr8pejiDrmENEXb0=";
      mods = [
        { url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/dZsorAUN/fabric-api-0.147.0%2B26.1.2.jar"; hash = "sha256-q3h3qPfI5HVw0+txBLL7LzoyT21lU1b+c5Z/LTKQurg="; }
        { url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/R7MxYvuW/lithium-fabric-0.24.2%2Bmc26.1.2.jar"; hash = "sha256-IlKJ8aLw4nSbNl9lpJwD6o9FJEXkmJmVEME8s5ndTgA="; }
        { url = "https://cdn.modrinth.com/data/VSNURh3q/versions/utLSz8Lf/c2me-fabric-mc26.1.2-0.3.7%2Balpha.0.68.jar"; hash = "sha256-Qe7RSuS2q+aq9n/r8BdM6EDgkwu+oqyfRx3eisQnCcc="; }
        { url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/kYAGItyj/krypton-0.3.0.jar"; hash = "sha256-dFsRFgQ0dC1EQFRqp+RF0U1ZuhJG5br5kdKTGQuplGM="; }
        { url = "https://cdn.modrinth.com/data/uXXizFIs/versions/d5ddUdiB/ferritecore-9.0.0-fabric.jar"; hash = "sha256-ITlmxy7ZZ6zHOSvrKKhm+6MB/1a5l2wueAHC233mvyI="; }
        ksyxis
        almanac
        letMeDespawn
      ];
    };
  };

  mkVariant =
    tag:
    {
      loader,
      mods ? [ ],
      ...
    }@cfg:
    { pkgs, ... }:
    {
      ix.image.tag = tag;
      services.minecraft.${loader} = (builtins.removeAttrs cfg [ "loader" "mods" ]) // {
        enable = true;
      };
      services.minecraft.mods = map pkgs.fetchurl mods;
    };
in
{
  inherit default;
}
// lib.mapAttrs mkVariant variants
