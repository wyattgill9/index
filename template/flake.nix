{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ix-images.url = "github:indexable-inc/images";
    ix-images.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { ix-images, ... }:
    {
      packages.x86_64-linux.default = ix-images.lib.mkIxImage {
        modules = [
          (
            { pkgs, ... }:
            {
              ix.image.name = "my-image";
              environment.systemPackages = [
                pkgs.curl
                pkgs.htop
              ];
              services.git-clone = {
                enable = true;
                url = "https://github.com/torvalds/linux.git";
              };
            }
          )
        ];
      };
    };
}
