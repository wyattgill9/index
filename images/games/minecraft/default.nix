{ minecraftVersion, fabricLoaderVersion, fabricInstallerVersion, serverJarHash }:
{
  ...
}:
{
  ix.image.name = "minecraft";
  ix.image.tag = "${minecraftVersion}-fabric";

  services.minecraft = {
    enable = true;
    inherit
      minecraftVersion
      fabricLoaderVersion
      fabricInstallerVersion
      serverJarHash
      ;
    memory = "2G";
    serverProperties = {
      motd = "ix-powered Minecraft";
      max-players = "20";
    };
  };
}
