# Folia server jar. PaperMC fork for regionized multithreading.
# Same API as Paper: https://api.papermc.io/v2/projects/folia/versions/<v>/builds/<b>
{
  ix,
  config,
  lib,
  pkgs,
  ...
}:
ix.mkMinecraftLoader {
  inherit config lib pkgs;
  name = "folia";
  dropDir = "plugins";
  urlFor =
    cfg:
    "https://api.papermc.io/v2/projects/folia/versions/${cfg.minecraftVersion}/builds/${toString cfg.build}/downloads/folia-${cfg.minecraftVersion}-${toString cfg.build}.jar";
  extraOptions = {
    minecraftVersion = lib.mkOption { type = lib.types.str; };
    build = lib.mkOption { type = lib.types.int; };
  };
}
