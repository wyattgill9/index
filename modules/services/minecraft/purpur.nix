# Purpur server jar. https://purpurmc.org
# Paper fork with extra gameplay and performance patches.
# API: https://api.purpurmc.org/v2/purpur/<version>/<build>/download
{
  ix,
  config,
  lib,
  ...
}:
ix.mkMinecraftLoader {
  inherit config lib;
  name = "purpur";
  dropDir = "plugins";
  extraOptions = {
    version = lib.mkOption { type = lib.types.str; };
    build = lib.mkOption { type = lib.types.int; };
  };
}
