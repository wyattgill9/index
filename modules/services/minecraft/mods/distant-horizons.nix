# Distant Horizons: server-side LOD generation for clients running DH.
#
# Activated when `services.minecraft.mods.distanthorizons` is set.
# Generates DistantHorizons.toml from the user's attrset (with defaults).
{ config, lib, ... }:
let
  modCfg = config.services.minecraft.mods.distanthorizons or null;
  defaults = {
    serverSideLodGeneration = true;
    maxRenderDistance = 256;
  };
  merged = defaults // (if modCfg == null then { } else modCfg);
in
{
  config = lib.mkIf (modCfg != null) {
    services.minecraft.configFiles."DistantHorizons.toml" = {
      server = {
        inherit (merged) serverSideLodGeneration maxRenderDistance;
      };
    };
  };
}
