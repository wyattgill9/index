# Hyperion Bedwars image.
{ config, ... }:
{
  ix.image = {
    name = "hyperion";
    tag = config.services.hyperion.package.version;
  };

  services.hyperion.enable = true;
}
