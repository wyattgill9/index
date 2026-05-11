# SpongeVanilla server jar. https://spongepowered.org
# Standalone Sponge implementation (no Forge needed).
# Maven: https://repo.spongepowered.org/repository/maven-releases/org/spongepowered/spongevanilla/
{
  ix,
  config,
  lib,
  ...
}:
ix.mkMinecraftLoader {
  inherit config lib;
  name = "sponge";
  dropDir = "mods";
  extraOptions = {
    version = lib.mkOption {
      type = lib.types.str;
      description = "Full SpongeVanilla version (e.g. 1.21.1-12.0.0).";
    };
  };
}
