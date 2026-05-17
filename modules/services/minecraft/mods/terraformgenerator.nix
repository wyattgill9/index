# TerraformGenerator: Bukkit world generation.
#
# Activated when `services.minecraft.plugins.terraformgenerator` is set.
# Binds the generator to the plugin's `worlds`, or the configured `level-name`
# when the world list is left implicit.
{ config, lib, ... }:
let
  cfg = config.services.minecraft;
  pluginCfg = cfg.plugins.terraformgenerator or null;
  defaultWorldName = cfg.properties."level-name" or "world";
  worldNames = pluginCfg.worlds or [ defaultWorldName ];
in
{
  config = lib.mkIf (pluginCfg != null) {
    services.minecraft.worlds = lib.genAttrs worldNames (_: {
      generator = lib.mkDefault "TerraformGenerator";
    });
  };
}
