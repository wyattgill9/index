# Factions Server

Standalone downstream-style example for a Paper factions server on ix.

It uses Paper `26.1.2` with a generated Paper plugin catalog entry for:

- PvPIndex Factions, TeamsAPI, PlaceholderAPI, LuckPerms
- WorldEdit and WorldGuard for spawn/admin regions
- TerraformGenerator for custom overworld generation
- Simple Voice Chat and Distant Horizons Support

The plugin URLs and hashes are not owned by this example. They come from
`images/games/minecraft/plugins/paper/manifest.json`, regenerated from the repo
root with:

```bash
nix run .#update-mods -- --manifest images/games/minecraft/plugins/paper/manifest.json
```

## Use

From this directory:

```bash
nix run .#plan      # show the resolved fleet plan
nix run .#diff      # compare desired systems with live ix state
nix run .#up        # build/upload the image and create or start the VM
nix run .#switch    # switch the VM in place
nix run .#replace   # recreate the VM from the replacement image
```
