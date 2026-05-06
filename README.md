# ix/images

NixOS images and modules for [ix](https://ix.dev) VMs. Built with `-march=znver5` for AMD EPYC Gen 5.

## Fleets

Groups of VMs that reference each other's config:

```nix
ix-images.lib.mkFleet {
  nodes = {
    db.services.ix-postgresql.enable = true;

    lobby = { nodes, ... }: {
      services.minecraft.paper = {
        enable = true;
        serverFiles."server.properties".motd =
          "db: ${nodes.db.config.networking.hostName}";
      };
    };
  };
}
```

Fleets are VM-level NixOS systems, not primarily OCI rollouts. The OCI image is a bootstrap artifact for creating or intentionally replacing a VM; normal stateful updates use `switch` to activate a new NixOS system closure in place. ix VMs have implicit snapshots and effectively unbounded disk, so stateful services should snapshot before data-format changes and upgrade persistent data directly instead of replacing the VM.

Outputs `packages.<node>` (bootstrap OCI archives), `plan` (JSON), `command`, and `switch`.

```nix
apps.switch.program = "${fleet.switch}/bin/ix-fleet-switch";
```

`nix run .#switch` snapshots and switches nodes in dependency order. Use `ix-fleet replace` only when VM recreation is intended.

## Contributing

Drop `images/<category>/<name>/default.nix`. See [AGENTS.md](AGENTS.md). [MIT](LICENSE).
