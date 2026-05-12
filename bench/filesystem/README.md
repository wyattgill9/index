# Filesystem Bench

Small benchmark for comparing the file system a VM sees. It is meant for VCFS
smoke checks, before/after comparisons, and quick regressions against a normal
disk-backed directory.

Run it inside the VM so the benchmark exercises the same path applications use:

```sh
nix run github:indexable-inc/index#bench-filesystem -- --target /path/to/vcfs
```

For a local checkout:

```sh
nix run .#bench-filesystem -- --target /path/to/vcfs
```

For a short sanity check:

```sh
nix run .#bench-filesystem -- --target /path/to/vcfs --quick
```

To compare two file systems, run the same command twice with different targets,
for example `/path/to/vcfs` and `/tmp` or another ext4-backed directory.

The benchmark reports:

- Sequential read and write throughput using 1 MiB blocks.
- Random read and write IOPS using 4 KiB blocks.
- Create, stat, and delete rates for many tiny files.

Use `--json` when collecting results:

```sh
nix run .#bench-filesystem -- --target /path/to/vcfs --json > vcfs.json
```

This is intentionally not a CI pass/fail test. The useful signal is relative:
same VM, same benchmark parameters, different target directories or different
VCFS builds.
