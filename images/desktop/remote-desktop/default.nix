# Remote desktop image: bare X session reachable over noVNC, plus xterm and
# firefox so there's something to look at on first boot.
{ pkgs, ... }:
{
  ix.image.name = "ix-remote-desktop";

  environment.systemPackages = [
    pkgs.xterm
    pkgs.firefox
  ];

  services.remote-desktop.enable = true;
}
