# Minecraft Fleet

This directory is a small ix fleet with one Paper server. Paper is used because Bukkit-family plugins have the best reload story in this repo: managed plugin changes trigger the Minecraft unit's `reload` path, and PlugManX reloads the changed plugin over local RCON without restarting the server.

```text
examples/minecraft-fleet/
  flake.nix    # exposes runnable fleet commands
  default.nix  # defines the single-node fleet
```

## Topology

- `minecraft` is the only VM.
- Paper 1.21.11 runs the server.
- LuckPerms is a managed plugin.
- PlugManX is added automatically by `services.minecraft.autoReload` when the `plugman` driver is active.
- Java players enter on TCP 25565.

## Network Exposure

Every VM automatically has both network planes. This example only exposes the Minecraft port publicly:

```nix
deployment.expose.northSouth.tcp = [ 25565 ];
```

## Hot Reload

`services.minecraft.autoReload.driver = "plugman"` makes managed plugin changes reload instead of restarting the Minecraft service. The runtime syncs declarative plugins into `/var/lib/minecraft/plugins`, computes a per-plugin plan from the previous manifest, and sends `plugman load`, `plugman reload`, or `plugman unload` over local RCON.

## Use

From this directory:

```bash
nix run .#plan -- plan      # show the resolved fleet plan
nix run .#plan -- diff      # compare desired systems with live ix state
nix run .#switch
nix run .#replace -- replace
```

`switch` snapshots and switches nodes in dependency order. Use `replace` only when VM recreation is intended.

If ix grows a first-class command wrapper, the same flow should become:

```bash
ix fleet plan
ix fleet diff
ix switch
ix replace
```
