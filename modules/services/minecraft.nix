{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.services.minecraft;
in
{
  options.services.minecraft = {
    enable = mkEnableOption "Minecraft server (Fabric)";

    minecraftVersion = mkOption {
      type = types.str;
      default = "26.2-snapshot-5";
    };

    fabricLoaderVersion = mkOption {
      type = types.str;
      default = "0.19.2";
    };

    fabricInstallerVersion = mkOption {
      type = types.str;
      default = "1.1.1";
    };

    serverJarHash = mkOption {
      type = types.str;
    };

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

  config = mkIf cfg.enable (
    let
      serverJar = pkgs.fetchurl {
        url = "https://meta.fabricmc.net/v2/versions/loader/${cfg.minecraftVersion}/${cfg.fabricLoaderVersion}/${cfg.fabricInstallerVersion}/server/jar";
        hash = cfg.serverJarHash;
      };

      propsFile = pkgs.writeText "server.properties" (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (k: v: "${k}=${v}") (
            { server-port = toString cfg.port; } // cfg.serverProperties
          )
        )
      );

      dataDir = "/var/lib/minecraft";
    in
    {
      networking.firewall.allowedTCPPorts = [ cfg.port ];

      systemd.services.minecraft = {
        description = "Minecraft Fabric server";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ cfg.jdk ];
        serviceConfig = {
          Type = "simple";
          WorkingDirectory = dataDir;
          ExecStart = "${cfg.jdk}/bin/java -Xms1G -Xmx${cfg.memory} -jar ${serverJar} nogui";
          Restart = "on-failure";
        };
        preStart =
          let
            modLinks = lib.concatMapStrings (
              mod: "ln -sf ${mod} ${dataDir}/mods/\n"
            ) cfg.mods;
          in
          ''
            mkdir -p ${dataDir}/mods
            ln -sf ${propsFile} ${dataDir}/server.properties
            echo "eula=true" > ${dataDir}/eula.txt
            ${modLinks}
          '';
      };
    }
  );
}
