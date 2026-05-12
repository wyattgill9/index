# Browser-accessible remote desktop backed by Xpra's built-in HTML5 client.
{
  config,
  ix,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.services.remote-desktop;

  defaultSession = ix.writeNushellApplication pkgs {
    name = "ix-remote-desktop-session";
    runtimeInputs = [
      pkgs.icewm
      pkgs.xterm
    ];
    text = ''
      def main [] {
        job spawn { ^xterm }
        exec icewm-session
      }
    '';
  };

  launcher = ix.writeNushellApplication pkgs {
    name = "ix-remote-desktop";
    runtimeInputs = [
      cfg.package
    ];
    text = ''
      def main [] {
        let args = ${
          builtins.toJSON (
            [
              "start-desktop"
              cfg.display
              "--start=${cfg.desktopCommand}"
              "--bind-tcp=${cfg.bindAddress}:${toString cfg.port}"
              "--auth=${cfg.auth}"
              "--resize-display=${cfg.resolution}"
              "--socket-dirs=/run/remote-desktop"
              "--html=on"
              "--ssl=off"
              "--daemon=no"
              "--mdns=no"
              "--pulseaudio=no"
              "--notifications=no"
              "--webcam=no"
              "--printing=no"
              "--file-transfer=off"
              "--open-files=off"
              "--clipboard=on"
            ]
            ++ cfg.extraOptions
          )
        }
        exec xpra ...$args
      }
    '';
  };
in
{
  options.services.remote-desktop = {
    enable = mkEnableOption "browser-accessible Xpra remote desktop";

    package = mkPackageOption pkgs "xpra" { };

    port = mkOption {
      type = types.port;
      default = 6080;
      description = "TCP port for the Xpra HTML5 client.";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address Xpra binds for browser clients.";
    };

    display = mkOption {
      type = types.str;
      default = ":100";
      description = "X display number managed by Xpra.";
    };

    resolution = mkOption {
      type = types.str;
      default = "1920x1080";
      description = "Initial virtual display resolution.";
    };

    desktopCommand = mkOption {
      type = types.str;
      default = lib.getExe defaultSession;
      defaultText = lib.literalExpression ''"${lib.getExe defaultSession}"'';
      description = "Command Xpra starts as the desktop session.";
    };

    auth = mkOption {
      type = types.str;
      default = "none";
      description = "Xpra authentication module for incoming clients.";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional command-line options passed to Xpra.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.icewm
      pkgs.xterm
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    users.groups.remote-desktop = { };
    users.users.remote-desktop = {
      description = "Remote desktop service user";
      isSystemUser = true;
      group = "remote-desktop";
      home = "/var/lib/remote-desktop";
    };

    systemd.services.remote-desktop = {
      description = "Xpra remote desktop";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment.HOME = "/var/lib/remote-desktop";
      serviceConfig = {
        Type = "simple";
        User = "remote-desktop";
        Group = "remote-desktop";
        StateDirectory = "remote-desktop";
        RuntimeDirectory = "remote-desktop";
        WorkingDirectory = "/var/lib/remote-desktop";
        ExecStart = lib.getExe launcher;
        Restart = "on-failure";
      };
    };
  };
}
