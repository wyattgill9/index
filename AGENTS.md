# ix/images

Pre-built OCI images for ix VMs, plus composable NixOS modules.

## How it works

`mkIxImage` wraps `lib.nixosSystem` with `boot.isContainer = true`. The NixOS system closure is packaged as an OCI archive. CI pre-builds images and publishes to `registry.ix.dev/ix/`. Users reference them directly: `ix new minecraft`.

## Directory structure

```
images/
  games/minecraft/default.nix
  dev/kernel-dev/default.nix
  desktop/remote-desktop/default.nix
modules/
  module-list.nix
  services/
lib/
  default.nix
  ix-base.nix
  docker-to-oci.py
```

## Module conventions

- Modules define `options` and `config`. They never import other modules.
- `module-list.nix` registers all modules using `./` paths. No `..` anywhere.
- Use standard NixOS options: `environment.systemPackages`, `systemd.services`, `networking.firewall`.
- Images are pure config with no `imports`.
- Guard config behind `mkIf cfg.enable`.

## Adding an image

1. Create `images/<category>/<name>/default.nix`
2. Wire into `flake.nix` packages
3. For versioned images, take version args and create versioned attrs (`minecraft_26w17a`) with a default alias (`minecraft`)

## Adding a module

1. Create `modules/services/<name>.nix`
2. Add to `modules/module-list.nix`

## Nix style

- No `with pkgs;` or `with lib;` (ast-grep enforced)
- No `writeShellScriptBin`, use `writeShellScript`
- `__structuredAttrs = true` on all derivations
- SRI hashes (`hash = "sha256-..."`)
- No `rec { }`
- x86_64-linux only

## Lint

```
nix run nixpkgs#ast-grep -- scan
```
