# ix/images

Pre-built OCI images for ix VMs, plus composable NixOS modules.

## How it works

Every image is an independent NixOS system closure: `boot.isContainer = true`, systemd as PID 1, no kernel, no bootloader. `lib.mkIxImage` runs `nixpkgs.lib.nixosSystem` over the implicit base layer (`lib/ix-base.nix`), the module registry (`modules/`), and any caller modules, then packages the toplevel into an OCI archive via `dockerTools.streamLayeredImage` plus a small docker-archive-to-OCI converter (`lib/docker-to-oci.py`).

Images are not stacked at runtime. ix runs one image. Layering is purely a build-time concern: the closure is split into ~67 OCI layers so the registry stores each shared store path once and clients only pay for deltas. Single-layer would force every image to ship a private copy of the multi-hundred-MB base closure.

## Layout

```
flake.nix                       # pure: ix.discoverImages ./images
lib/
  default.nix                   # mkIxImage, discoverImages
  ix-base.nix                   # implicit base layer (every image)
  docker-to-oci.py              # docker-archive -> OCI archive transcoder
modules/
  default.nix                   # canonical module registry (attrset)
  profiles/base.nix             # CLI tools, on by default
  services/<name>.nix           # opt-in services
images/
  <category>/<name>/default.nix # NixOS module
  <category>/<name>/versions.nix# optional: per-version overlay modules
template/                       # `nix flake init` starter
nix/rules/                      # ast-grep lint rules
```

## Adding an image

Drop a NixOS module at `images/<category>/<name>/default.nix`. That's it: discovery picks it up on the next eval and exposes `packages.x86_64-linux.<name>`. No flake edits, no registry edits.

For a versioned image (multiple variants ship at once), add a `versions.nix` sibling:

```nix
{
  default = "26w17a";
  "26w17a" = {
    ix.image.tag = "26w17a-fabric";
    services.minecraft = { /* version-specific args */ };
  };
}
```

Discovery then exposes `<name>_<ver>` for each version key plus `<name>` as an alias for the `default` version.

## Adding a module

Drop the file at `modules/services/<name>.nix` (or `modules/profiles/<name>.nix`) and register it in `modules/default.nix`. Keep modules independent: declare `options`, gate everything behind `mkIf cfg.enable`, never import another module. The registry exists so option sets are visible to every image; modules stay inert until their `enable` flag is set.

## Module conventions

- Modules declare options and config. They never `imports` another module.
- Top-level options live under `services.<name>` for services, `ix.profiles.<name>` for profiles. Never reach into another module's namespace.
- Everything in `config` is wrapped in `mkIf cfg.enable`. The base profile is the only exception: it ships an enable flag so users can opt out.
- Module options take strings or paths, not factory arguments. Versioning belongs in `versions.nix`, not in a function wrapping the module.

## Image conventions

- Images set `ix.image.name`. They may set `ix.image.tag` (defaults to `latest`, or comes from `versions.nix`).
- Images compose by enabling services and adding packages. They do not declare options. They do not `imports` anything.
- Images stay version-agnostic when they have a `versions.nix`. The base file is what every variant shares; per-version data lives in the overlay.

## Nix philosophy

- **Single source of truth.** `modules/default.nix` is the only place modules are listed; `attrValues` derives the list. Versions live next to the image in `versions.nix`, not in `flake.nix`.
- **No backwards compat.** This repo is young and has no external consumers. Rename freely, change signatures, delete dead code. No shims, no aliases, no `// removed` comments, no feature flags for the old way. Update callers in the same change.
- **Auto-discover, don't enumerate.** `flake.nix` walks `images/`. Adding an image is `mkdir + edit one file`. Hand-wired registries rot.
- **DRY at the data layer, not the abstraction layer.** `inherit (pkgs) ...` over a wrapper helper. `attrValues` over a parallel list. Don't introduce a function unless it has at least two callers.
- **Comments explain why, not what.** Headers say what each file is for and what's load-bearing (e.g. `maxLayers = 67` with the registry-cap rationale, base profile auto-enabled). Don't restate what the code obviously does.
- **Trust module merging.** Layer per-version overlays via the module system, not by passing args to factory functions.
- **Pure eval.** No `builtins.currentSystem`, no `builtins.getEnv`, no `<nixpkgs>` channel refs, no `path:` flake refs. Every input flows through `flake.nix`.
- **Strict, named failures.** `lib.assertMsg` over bare `assert`. Required options have no default so misuse fails at eval with the option name, not at runtime with a NullPointerException.

## Nix style (ast-grep enforced)

Run `nix run nixpkgs#ast-grep -- scan` before committing. Hard rules:

- No `with pkgs;` or `with lib;`. Use `inherit (pkgs) ...` or `lib.foo` directly.
- No `rec { }`. Use `let ... in` or `final/prev` instead.
- No `mkForce`. Resolve conflicts with priority composition or fix the module boundary.
- No `lib.recursiveUpdate`. Build the attrset in one place or use `lib.mkMerge`.
- No `builtins.currentSystem`, `builtins.getEnv`, `<nixpkgs>`, or `path:` flake refs.
- No `(import ./foo.nix)` inside `imports = [ ... ]`. NixOS auto-imports paths.
- No `writeShellScriptBin`. Use `writeShellScript` (or `writeShellApplication` for orchestrators).
- No bare `assert cond;`. Use `assert lib.assertMsg cond "why";`.
- `__structuredAttrs = true` on every `runCommand` and `mkDerivation`. `mkDerivation` also gets `strictDeps = true`.
- `hash = "sha256-...="` (SRI) on fetchers. Never `sha256 = ...`.
- x86_64-linux only. `system` is a single string, not a `forAllSystems` fold.

## Linting

```
nix run nixpkgs#ast-grep -- scan
```
