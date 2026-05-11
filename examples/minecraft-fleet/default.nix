{
  ix,
  hostSystem ? ix.lib.system,
}:
let
  pluginCatalog = ix.lib.artifacts.attachArtifactSources {
    luckperms.url = "https://cdn.modrinth.com/data/Vebnzrzj/versions/OrIs0S6b/LuckPerms-Bukkit-5.5.17.jar";
  };
in
(ix.lib.mkFleetFor hostSystem) {
  deployment.switch = {
    buildOn = "remote";
    overrideInputs.index = ".";
  };

  nodes = {
    minecraft = {
      deployment.expose.northSouth.tcp = [ 25565 ];
      modules = [
        (
          { ix, ... }:
          {
            ix.image = {
              name = "minecraft";
              tag = "paper-hot-reload";
            };

            services.minecraft = {
              enable = true;

              paper = {
                enable = true;
                version = "1.21.11";
                build = 69;
                src = ix.artifacts.minecraft.servers."1.21.11-paper";
              };

              mods.luckperms = { };
              modCatalog = pluginCatalog;

              autoReload = {
                enable = true;
                driver = "plugman";
                plugman.pluginNames.luckperms = "LuckPerms";
              };

              serverFiles."server.properties" = {
                motd = "ix Paper";
                max-players = 20;
                online-mode = true;
                view-distance = 10;
                simulation-distance = 8;
              };
            };
          }
        )
      ];
    };
  };
}
