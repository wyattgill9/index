# TerraformGenerator: Bukkit world generation.
#
# Activated when `services.minecraft.plugins.terraformgenerator` is set.
# Binds the generator to the configured `level-name`, or Minecraft's default
# world name when the server properties leave it implicit.
{ config, lib, ... }:
let
  cfg = config.services.minecraft;
  pluginCfg = cfg.plugins.terraformgenerator or null;
  worldName = cfg.properties."level-name" or "world";
in
{
  config = lib.mkIf (pluginCfg != null) {
    services.minecraft.bukkit.worlds.${worldName}.generator = lib.mkDefault "TerraformGenerator";
  };
}
