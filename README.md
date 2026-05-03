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
