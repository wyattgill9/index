{
  pkgs,
  ...
}:
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
