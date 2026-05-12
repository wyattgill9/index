# Contributing

Use the Nix development shell so local tooling matches CI:

```sh
nix develop
```

The dev shell installs the repo pre-commit hook. The hook runs the same lint entry point contributors should run manually before pushing:

```sh
nix run .#lint
```

This checks Nix formatting, Statix, Deadnix, and the repo ast-grep rules. Keep `nix run .#lint` as the source of truth when changing lint behavior.
