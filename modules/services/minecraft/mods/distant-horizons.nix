# Distant Horizons: server-side LOD generation for clients running DH.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.minecraft.mod.distant-horizons;
  toml = pkgs.formats.toml { };
in
{
  options.services.minecraft.mod.distant-horizons = {
    enable = lib.mkEnableOption "Distant Horizons LOD generation";
    serverSideLodGeneration = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    maxRenderDistance = lib.mkOption {
      type = lib.types.int;
      default = 256;
    };
  };

  config = lib.mkIf cfg.enable {
    services.minecraft.extraModSlugs = [ "distanthorizons" ];
    services.minecraft.configFiles."DistantHorizons.toml" = toml.generate "DistantHorizons.toml" {
      server = {
        inherit (cfg) serverSideLodGeneration maxRenderDistance;
      };
    };
  };
}
