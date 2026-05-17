{ world }:

{
  autoReloadIgnored = [
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
    "BlueMap"
    "Skript"
  ];

  enabled = {
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
    bluemap = { };
    skript = { };
  };
}
