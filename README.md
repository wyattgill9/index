# ix/images

Pre-built OCI images for [ix](https://ix.dev) VMs.

```bash
ix new minecraft          # Fabric server
ix new remote-desktop     # Xpra HTML5 desktop
ix new kernel-dev         # Linux kernel source + build tools
```

See [`images/`](images) for all available images.

## Build from source

```bash
nix build github:indexable-inc/images#minecraft
ix push ./result minecraft
```

## Custom images

Compose with NixOS modules:

```nix
ix-images.lib.mkIxImage {
  modules = [({ pkgs, ... }: {
    ix.image.name = "my-server";
    services.minecraft.enable = true;
    services.remote-desktop.enable = true;
    environment.systemPackages = [ pkgs.htop pkgs.vim ];
  })];
}
```

### Fabric server with Distant Horizons

```nix
# images/games/my-mc/default.nix
{ ... }:
{
  ix.image.name = "my-mc";

  services.minecraft = {
    memory = "8G";
    serverProperties = {
      view-distance = 32;
      simulation-distance = 12;
      max-players = 10;
    };
    mod.distant-horizons = {
      enable = true;
      maxRenderDistance = 512;
    };
    mod.chunky.enable = true;
  };

  services.minecraft.fabric = {
    enable = true;
    minecraftVersion = "26.1.2";
    loaderVersion = "0.19.2";
    installerVersion = "1.1.1";
    hash = "sha256-6RvRm5/w4ExXhD5iTS9U0KPjmgSMr8pejiDrmENEXb0=";
    mods = [ "fabric-api" "lithium" "c2me-fabric" ];
    modCatalog = builtins.fromJSON (builtins.readFile ./mods.json);
  };
}
```

Mod modules handle the jar slug and config generation. Enable a mod, set its options, done. Mods without a module (like `lithium`) stay as raw slugs in the loader's `mods` list.

Generate `mods.json` with `python3 tools/update-mods.py`. Mods are resolved by [Modrinth](https://modrinth.com) slug.

All [NixOS options](https://search.nixos.org/options) work. Images are NixOS configs with systemd as PID 1.

## Contributing

Community contributions are welcome through [issues](https://github.com/indexable-inc/images/issues) and [pull requests](https://github.com/indexable-inc/images/pulls). Add `images/<category>/<name>/default.nix`; discovery wires it into the flake. See [AGENTS.md](AGENTS.md) for conventions.

## Related

- [ix](https://ix.dev) - the platform
- [ix docs](https://github.com/indexable-inc/docs) - platform documentation
- [ix CLI](https://github.com/indexable-inc/ix) - command-line interface
- [NixOS](https://nixos.org) - the module system and packages underneath

Inspired by [nixpkgs](https://github.com/NixOS/nixpkgs) and [Raycast Extensions](https://github.com/raycast/extensions).

## License

[MIT](LICENSE). The license applies to the Nix expressions and modules in this repository, not to the software packaged within the images.
