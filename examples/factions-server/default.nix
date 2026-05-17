{ index }:
let
  world = {
    name = "factions";
    seed = "4504535438041489910";
    border = {
      radius = 6000;
      diameter = 12000;
    };
  };
in
index.lib.mkFleet {
  # The tag is shared by every replacement image this example builds, so
  # registry destinations read `factions:factions-server` instead of `:latest`.
  defaults = [ { ix.image.tag = "factions-server"; } ];

  nodes.factions = {
    deployment.ipv4 = true;

    modules = [
      (
        { lib, ... }:
        {
          services.minecraft = {
            enable = true;
            version = "26.1.2";
            paper.enable = true;

            # Local RCON is required for the managed world border and PlugManX
            # reloads. It stays off the firewall unless rcon.openFirewall is set.
            rcon = {
              enable = true;
              broadcastToOps = false;
            };

            autoReload.plugman.ignoredPlugins = lib.mkAfter [
              "Vault"
              "LuckPerms"
              "PlaceholderAPI"
              "TeamsAPI"
              "WorldEdit"
              "WorldGuard"
              "EternalEconomy"
              "QuickShop-Hikari"
              "TradePost"
              "PvPIndexFactions"
              "CombatLog"
            ];

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
              vaultunlocked = { };
              eternaleconomy = { };
              quickshop-hikari = { };
              tradepost = { };
              worldedit = { };
              worldguard = { };
              terraformgenerator.worlds = [
                world.name
                "${world.name}_nether"
                "${world.name}_the_end"
              ];
              pvpindex-factions = { };
              combatlogplugin = { };
              simple-voice-chat = { };
              distant-horizons-support = { };
            };

            properties = {
              motd = "ix Factions | territory, raids, shops";
              difficulty = "hard";
              gamemode = "survival";
              level-name = world.name;
              level-seed = world.seed;
              max-players = 250;
              spawn-protection = 0;
              view-distance = 16;
              simulation-distance = 10;
              max-world-size = world.border.radius;
              pvp = true;
            };

            worldBorder = {
              enable = true;
              inherit (world.border) diameter;
              center = {
                x = 0;
                z = 0;
              };
              warning = {
                distance = 64;
                time = 15;
              };
              damage = {
                buffer = 16;
                amount = 0.2;
              };
            };

            bukkit = {
              settings = {
                allow-end = true;
                warn-on-overload = true;
                query-plugins = false;
                shutdown-message = "Factions is restarting";
                deprecated-verbose = "default";
              };

              spawn-limits = {
                monsters = 70;
                animals = 10;
                water-animals = 5;
                water-ambient = 20;
                water-underground-creature = 5;
                axolotls = 5;
                ambient = 15;
              };

              chunk-gc.period-in-ticks = 600;

              ticks-per = {
                animal-spawns = 400;
                monster-spawns = 1;
                water-spawns = 1;
                water-ambient-spawns = 1;
                water-underground-creature-spawns = 1;
                axolotl-spawns = 1;
                ambient-spawns = 1;
                autosave = 6000;
              };
            };

            configFiles = {
              "paper-global.yml" = {
                chunk-loading-basic = {
                  player-max-chunk-load-rate = 100;
                  player-max-chunk-generate-rate = -1.0;
                  player-max-chunk-send-rate = 75;
                };

                chunk-loading-advanced = {
                  auto-config-send-distance = true;
                  player-max-concurrent-chunk-loads = 0;
                  player-max-concurrent-chunk-generates = 0;
                };

                player-auto-save = {
                  rate = -1;
                  max-per-tick = -1;
                };

                scoreboards = {
                  save-empty-scoreboard-teams = false;
                  track-plugin-scoreboards = false;
                };

                spam-limiter = {
                  incoming-packet-threshold = 300;
                  recipe-spam-limit = 20;
                  tab-spam-limit = 500;
                };

                spark = {
                  enabled = true;
                  enable-immediately = false;
                };

                unsupported-settings = {
                  allow-headless-pistons = false;
                  allow-permanent-block-break-exploits = false;
                  allow-piston-duplication = false;
                  allow-unsafe-end-portal-teleportation = false;
                  perform-username-validation = true;
                };

                watchdog = {
                  early-warning-delay = 10000;
                  early-warning-every = 5000;
                };
              };

              "paper-world-defaults.yml" = {
                chunks = {
                  auto-save-interval = "default";
                  delay-chunk-unloads-by = "10s";
                  max-auto-save-chunks-per-tick = 24;
                  prevent-moving-into-unloaded-chunks = true;
                };

                collisions = {
                  allow-player-cramming-damage = false;
                  max-entity-collisions = 8;
                  only-players-collide = false;
                };

                entities = {
                  spawning = {
                    count-all-mobs-for-spawning = false;
                    despawn-range-shape = "ELLIPSOID";
                    per-player-mob-spawns = true;
                    spawn-limits = {
                      ambient = -1;
                      axolotls = -1;
                      creature = -1;
                      monster = -1;
                      underground_water_creature = -1;
                      water_ambient = -1;
                      water_creature = -1;
                    };
                  };
                };

                environment = {
                  locate-structures-outside-world-border = false;
                  nether-ceiling-void-damage-height = 128;
                  optimize-explosions = true;
                  portal-search-radius = 96;
                };

                misc = {
                  disable-sprint-interruption-on-attack = false;
                  redstone-implementation = "VANILLA";
                  update-pathfinding-on-block-update = true;
                };
              };
            };

            serverFiles."spigot.yml" = {
              settings = {
                bungeecord = false;
                debug = false;
                log-named-deaths = false;
                log-villager-deaths = false;
                moved-too-quickly-multiplier = 10.0;
                moved-wrongly-threshold = 0.0625;
                netty-threads = 4;
                player-shuffle = 0;
                restart-on-crash = false;
                sample-count = 12;
                save-user-cache-on-stop-only = false;
                timeout-time = 60;
                user-cache-size = 1000;
              };

              messages = {
                whitelist = "You are not whitelisted on this server.";
                server-full = "Factions is full. Try again soon.";
                restart = "Factions is restarting.";
              };

              commands = {
                log = true;
                tab-complete = 0;
                send-namespaced = true;
              };

              world-settings.default = {
                below-zero-generation-in-existing-chunks = true;
                dragon-death-sound-radius = 0;
                end-portal-sound-radius = 0;
                hanging-tick-frequency = 100;
                wither-spawn-sound-radius = 0;
                item-despawn-rate = 6000;
                mob-spawn-range = 6;
                max-tnt-per-tick = 500;
                view-distance = "default";
                simulation-distance = "default";
                verbose = false;

                merge-radius = {
                  item = 2.5;
                  exp = 4.0;
                };

                ticks-per = {
                  hopper-check = 1;
                  hopper-transfer = 8;
                };

                hopper-amount = 1;
                hopper-can-load-chunks = false;

                entity-activation-range = {
                  animals = 24;
                  monsters = 32;
                  raiders = 48;
                  misc = 16;
                  water = 16;
                  villagers = 32;
                  flying-monsters = 48;
                  tick-inactive-villagers = true;
                };

                entity-tracking-range = {
                  players = 128;
                  animals = 64;
                  monsters = 64;
                  misc = 32;
                  display = 128;
                  other = 64;
                };
              };
            };
          };
        }
      )
    ];
  };
}
