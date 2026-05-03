{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.services.remote-desktop;
in
{
  options.services.remote-desktop = {
    enable = mkEnableOption "remote desktop via Xvfb + x11vnc + noVNC";

    resolution = mkOption {
      type = types.str;
      default = "1920x1080x24";
    };

    port = mkOption {
      type = types.port;
      default = 6080;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.xorg.xorgserver
      pkgs.x11vnc
      pkgs.novnc
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.xvfb = {
      description = "Xvfb display server";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xorg.xorgserver}/bin/Xvfb :99 -screen 0 ${cfg.resolution}";
        Restart = "always";
      };
    };

    systemd.services.x11vnc = {
      description = "x11vnc server";
      after = [ "xvfb.service" ];
      requires = [ "xvfb.service" ];
      wantedBy = [ "multi-user.target" ];
      environment.DISPLAY = ":99";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :99 -rfbport 5900 -forever -shared -nopw";
        Restart = "always";
      };
    };

    systemd.services.novnc = {
      description = "noVNC websocket proxy";
      after = [ "x11vnc.service" ];
      requires = [ "x11vnc.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.novnc}/bin/websockify --web ${pkgs.novnc}/share/novnc ${toString cfg.port} localhost:5900";
        Restart = "always";
      };
    };
  };
}
