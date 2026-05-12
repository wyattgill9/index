# Index

NixOS images and modules for [ix](https://ix.dev) VMs. Built with `-march=znver5` for AMD EPYC Gen 5.

## Building

Images always target Linux. The flake exposes the same Linux image derivations under both `packages.x86_64-linux` and `packages.aarch64-darwin`, so macOS users can run the normal short form:

```sh
nix build .#minecraft
```

Building on macOS still needs a Linux builder configured for the resulting `x86_64-linux` derivation.

## Fleets

Fleets are VM-level NixOS systems, not primarily OCI rollouts. Missing VMs are created from a shared ix NixOS bootstrap image, then `switch` activates the desired system closure in place. Node-specific OCI archives are only for intentional VM replacement.

See [examples/claude-code-demo/README.md](examples/claude-code-demo/README.md) for a Claude Code demo fleet with one Paper server and managed plugin hot reload.

Outputs `packages.<node>` (replacement OCI archives), `packages.<node>-system` (NixOS systems), `plan` (JSON), `command`, and `switch`.

```nix
apps.switch.program = "${fleet.switch}/bin/ix-fleet-switch";
```

`nix run .#switch` snapshots and switches nodes in dependency order. Use `ix-fleet replace` only when VM recreation is intended.

## Benchmarks

`bench/filesystem` is a small VM-side file system benchmark for VCFS smoke checks and before/after comparisons:

```sh
nix run .#bench-filesystem -- --target /path/to/vcfs
```

It measures sequential throughput, random 4 KiB I/O, and create/stat/delete metadata rates. See [bench/filesystem/README.md](bench/filesystem/README.md).

## Contributing

Drop `images/<category>/<name>/default.nix`. See [AGENTS.md](AGENTS.md). [MIT](LICENSE).
