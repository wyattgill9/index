# Minecraft server runtime.
#
# Loader-agnostic. Provides systemd unit, server.properties templating, mods,
# Java runtime, port. `serverJar` and `dropDir` are slots filled by a loader
# module (`./fabric.nix`, `./paper.nix`, `./vanilla.nix`, ...) via module
# merging. `dropDir` is where `mods` jars get symlinked: fabric uses `mods`,
# paper uses `plugins`.
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
    types
    ;
  cfg = config.services.minecraft;

  dataDir = "/var/lib/minecraft";

  # Pin server-port so the systemd-managed firewall and the running server agree.
  propsFile = pkgs.writeText "server.properties" (
    ix.toProperties (cfg.serverProperties // { server-port = cfg.port; })
  );

  modLinks = lib.concatMapStrings (mod: "ln -sf ${mod} ${dataDir}/${cfg.dropDir}/\n") cfg.mods;

  # Infer serialization format from file extension.
  formatFor =
    path:
    let
      ext = lib.last (lib.splitString "." path);
    in
    {
      toml = pkgs.formats.toml { };
      json = pkgs.formats.json { };
      yaml = pkgs.formats.yaml { };
      yml = pkgs.formats.yaml { };
      properties = pkgs.formats.keyValue { };
    }
    .${ext}
      or (throw "configFiles: unsupported extension .${ext} on '${path}'");

  configLinks = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      path: value:
      let
        file = (formatFor path).generate (builtins.baseNameOf path) value;
      in
      "mkdir -p ${dataDir}/config/${builtins.dirOf path}\nln -sf ${file} ${dataDir}/config/${path}"
    ) cfg.configFiles
  );

  javaArgs = [
    "${cfg.javaPackage}/bin/java"
    "-Xms${cfg.memory}"
    "-Xmx${cfg.memory}"
  ]
  ++ cfg.jvmFlags
  ++ [
    "-jar"
    "${cfg.serverJar}"
    "nogui"
  ];
in
{
  options.services.minecraft = {
    enable = mkEnableOption "Minecraft server runtime";

    serverJar = mkOption {
      type = types.package;
      description = "Server jar to launch. Set by a loader module (fabric/paper/vanilla).";
    };

    dropDir = mkOption {
      type = types.str;
      default = "mods";
      description = "Subdirectory under the data dir where `mods` jars are symlinked. Loaders set this: fabric → `mods`, paper → `plugins`.";
    };

    memory = mkOption {
      type = types.str;
      default = "2G";
    };

    mods = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra jars to symlink into `dropDir`. Fabric mods or Paper plugins, depending on the loader.";
    };

    javaPackage = mkOption {
      type = types.package;
      default = pkgs.graalvmPackages.graalvm-ce;
    };

    jvmFlags = mkOption {
      type = types.listOf types.str;
      default = [
        # Aikar's flags: https://mcflags.emc.gs
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+DisableExplicitGC" # prevent plugins from triggering full GC
        "-XX:+AlwaysPreTouch" # zero pages at startup so allocation never page-faults

        # large young gen: MC allocates heavily per tick, then discards
        "-XX:G1NewSizePercent=30"
        "-XX:G1MaxNewSizePercent=40"
        "-XX:G1HeapRegionSize=8M" # fewer regions = less bookkeeping
        "-XX:G1ReservePercent=20" # headroom so promotion doesn't force emergency collection

        # mixed GC tuning: reclaim old-gen without long pauses
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=15" # start concurrent mark early
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"

        "-XX:SurvivorRatio=32" # tiny survivor spaces: most objects die in eden
        "-XX:+PerfDisableSharedMem" # avoid mmap that causes GC stalls on some filesystems
        "-XX:MaxTenuringThreshold=1" # promote survivors immediately, don't copy between survivor spaces

        "-Dusing.aikars.flags=https://mcflags.emc.gs"
        "-Daikars.new.flags=true"
      ];
      description = "JVM flags used after heap sizing and before -jar.";
    };

    serverProperties = mkOption {
      type = types.attrsOf (types.oneOf [ types.str types.int types.bool ]);
      default = { };
    };

    configFiles = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      description = "Config files to place under config/. Keys are relative paths (format inferred from extension: .toml, .json, .yaml, .yml, .properties). Values are Nix attrsets.";
    };

    extraModSlugs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Mod slugs injected by mod modules. The active loader resolves these against its catalog alongside its own slug list.";
    };

    port = mkOption {
      type = types.port;
      default = 25565;
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.minecraft = {
      description = "Minecraft server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        WorkingDirectory = dataDir;
        ExecStart = lib.escapeShellArgs javaArgs;
        Restart = "on-failure";
        StateDirectory = "minecraft";

        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
      preStart = ''
        mkdir -p ${dataDir}/${cfg.dropDir}
        ln -sf ${propsFile} ${dataDir}/server.properties
        echo "eula=true" > ${dataDir}/eula.txt
        ${modLinks}
        ${configLinks}
      '';
    };
  };
}
