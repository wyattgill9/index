# Minecraft Bedrock server image.
{
  ix.image = {
    name = "minecraft-bedrock";
    tag = "1.26.14.1";
  };

  services.minecraft-bedrock = {
    enable = true;
    settings = {
      server-name = "ix-powered Bedrock";
      max-players = 20;
    };
  };
}
