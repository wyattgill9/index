{
  pkgs,
  ...
}:
{
  ix.image.name = "ix-remote-desktop";

  environment.systemPackages = [
    pkgs.xterm
    pkgs.firefox
  ];

  services.remote-desktop.enable = true;
}
