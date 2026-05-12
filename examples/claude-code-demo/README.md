# Claude Code Demo

Two VMs:

- `demo`: a shellable ix VM with `btop`, Linux source in `/src/linux`, and a tiny Svelte status page on port 80.
- `minecraft`: a Fabric server pinned to `26.2-snapshot-6`, creative mode, flat world, public Java port 25565.

## Run

```bash
nix run .#plan
nix run .#switch
```

## Demo Flow

Open the first VM shell and show the machine:

```bash
ix shell demo
btop
cd /src/linux
make -j$(nproc) defconfig bzImage
```

Open the `demo` web URL. The page is hosted inside the VM and shows live CPU usage out of 64 cores, memory usage out of 256 GiB, disk usage out of 1 PiB, and current cost per second.

Then use Minecraft:

```bash
ix shell minecraft
```

Join the server, take a snapshot, blow up the flat creative world with TNT, then switch or restore to show the stateful VM workflow. `switch` snapshots existing nodes before applying the new NixOS systems; `replace` is only for recreating VMs from OCI images.
