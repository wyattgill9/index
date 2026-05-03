# Linux kernel dev image: build toolchain and a shallow Linus tree at
# /src/linux. The base profile already brings ripgrep, fd, neovim, gdb, perf.
{ pkgs, ... }:
{
  ix.image.name = "linux-kernel-dev";

  environment.systemPackages = [
    pkgs.gnumake
    pkgs.gcc
    pkgs.gnugrep
    pkgs.findutils
  ];

  services.git-clone = {
    enable = true;
    url = "https://github.com/torvalds/linux.git";
    dest = "/src/linux";
  };
}
