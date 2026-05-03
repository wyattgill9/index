# Minecraft Fabric server image.
#
# This file is the version-agnostic base. Per-version data (upstream version
# strings, server JAR hash) lives in `./versions.nix` as overlay modules
# layered on top of this one by `lib.discoverImages`.
{
  ix.image.name = "minecraft";

  services.minecraft = {
    enable = true;
    serverProperties = {
      motd = "ix-powered Minecraft";
      max-players = "20";
    };
  };
}
