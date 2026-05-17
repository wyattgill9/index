{ index }:
index.lib.mkFleet {
  # The tag is shared by every replacement image this example builds, so
  # registry destinations read `factions:factions-server` instead of `:latest`.
  defaults = [ { ix.image.tag = "factions-server"; } ];

  nodes.factions = {
    deployment.ipv4 = true;

    modules = [
      (_: {
        services.minecraft = {
          enable = true;
          version = "26.1.2";
          paper.enable = true;
          rcon.enable = true;

          plugins = {
            luckperms = { };
            teams-api = { };
            placeholderapi = { };
            worldedit = { };
            worldguard = { };
            terraformgenerator = { };
            pvpindex-factions = { };
            simple-voice-chat = { };
            distant-horizons-support = { };
          };

          serverFiles = {
            "server.properties" = {
              motd = "ix Factions";
              max-players = 60;
              online-mode = true;
              enforce-secure-profile = true;
              gamemode = "survival";
              force-gamemode = false;
              difficulty = "hard";
              pvp = true;
              hardcore = false;
              spawn-protection = 16;
              level-name = "factions";
              level-seed = "4504535438041489910";
              view-distance = 12;
              simulation-distance = 8;
              allow-flight = false;
            };

            # TerraformGenerator is a Bukkit world generator. Paper reads the
            # generator binding from bukkit.yml before creating the world named
            # by `level-name`.
            "bukkit.yml" = {
              worlds.factions.generator = "TerraformGenerator";
            };
          };
        };
      })
    ];
  };
}
