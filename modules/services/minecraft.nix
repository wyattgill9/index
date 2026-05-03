# Minecraft Fabric server.
#
# Version triple + jar hash are required: the loader/installer URL pins to
# all three, and the upstream server jar is content-addressed via Nix. The
# minecraft image's `versions.nix` supplies them.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.services.minecraft;

  dataDir = "/var/lib/minecraft";

  serverJar = pkgs.fetchurl {
    url = "https://meta.fabricmc.net/v2/versions/loader/${cfg.minecraftVersion}/${cfg.fabricLoaderVersion}/${cfg.fabricInstallerVersion}/server/jar";
    hash = cfg.serverJarHash;
  };

  # Caller-provided properties win; we only force `server-port` so the
  # systemd-managed firewall and the running server agree.
  propsFile = pkgs.writeText "server.properties" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "${k}=${v}") (
        cfg.serverProperties // { server-port = toString cfg.port; }
      )
    )
  );

  modLinks = lib.concatMapStrings (mod: "ln -sf ${mod} ${dataDir}/mods/\n") cfg.mods;
in
{
  options.services.minecraft = {
    enable = mkEnableOption "Minecraft server (Fabric)";

    minecraftVersion = mkOption { type = types.str; };
    fabricLoaderVersion = mkOption { type = types.str; };
    fabricInstallerVersion = mkOption { type = types.str; };
    serverJarHash = mkOption { type = types.str; };

    memory = mkOption {
      type = types.str;
      default = "2G";
    };

    mods = mkOption {
      type = types.listOf types.package;
      default = [ ];
    };

    jdk = mkOption {
      type = types.package;
      default = pkgs.temurin-jre-bin-25;
    };

    serverProperties = mkOption {
      type = types.attrsOf types.str;
      default = { };
    };

    port = mkOption {
      type = types.port;
      default = 25565;
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.minecraft = {
      description = "Minecraft Fabric server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        WorkingDirectory = dataDir;
        ExecStart = "${cfg.jdk}/bin/java -Xms1G -Xmx${cfg.memory} -jar ${serverJar} nogui";
        Restart = "on-failure";
      };
      preStart = ''
        mkdir -p ${dataDir}/mods
        ln -sf ${propsFile} ${dataDir}/server.properties
        echo "eula=true" > ${dataDir}/eula.txt
        ${modLinks}
      '';
    };
  };
}
