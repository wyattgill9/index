# ServerCore: activation range, mob spawn tuning, entity limits.
{ config, lib, ... }:
let
  cfg = config.services.minecraft.mod.servercore;
in
{
  options.services.minecraft.mod.servercore = {
    enable = lib.mkEnableOption "ServerCore optimizations";
  };

  config = lib.mkIf cfg.enable {
    services.minecraft.extraModSlugs = [ "servercore" ];
  };
}
