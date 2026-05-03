# Chunky: server-side chunk pre-generation.
{ config, lib, ... }:
let
  cfg = config.services.minecraft.mod.chunky;
in
{
  options.services.minecraft.mod.chunky = {
    enable = lib.mkEnableOption "Chunky chunk pre-generation";
  };

  config = lib.mkIf cfg.enable {
    services.minecraft.extraModSlugs = [ "chunky" ];
  };
}
