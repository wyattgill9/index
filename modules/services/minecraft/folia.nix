# Folia server jar. https://papermc.io/software/folia
# PaperMC fork for regionized multithreading.
# API: https://api.papermc.io/v2/projects/folia/versions/<v>/builds/<b>
{
  ix,
  config,
  lib,
  ...
}:
ix.mkMinecraftLoader {
  inherit config lib;
  name = "folia";
  dropDir = "plugins";
  extraOptions = {
    version = lib.mkOption { type = lib.types.str; };
    build = lib.mkOption { type = lib.types.int; };
  };
}
