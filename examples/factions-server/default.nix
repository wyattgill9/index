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

          # Uncomment and add real Minecraft UUIDs to derive whitelist.json
          # and ops.json from one player record.
          # whitelist.enable = true;
          # players = {
          #   Alice = {
          #     uuid = "00000000-0000-0000-0000-000000000000";
          #     whitelist = true;
          #     operator.enable = true;
          #   };
          # };

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

          properties = {
            motd = "ix Factions";
            difficulty = "hard";
            level-name = "factions";
            level-seed = "4504535438041489910";
          };
        };
      })
    ];
  };
}
