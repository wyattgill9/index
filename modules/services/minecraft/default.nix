# Minecraft server runtime.
#
# Loader-agnostic. Provides systemd unit, mods, Java runtime, port.
# `serverJar` and `dropDir` are slots filled by a loader module (fabric,
# folia, neoforge, paper, purpur, spigot, sponge, vanilla) via module merging.
# `dropDir` is where mod jars get symlinked: fabric/neoforge/sponge use
# `mods`, paper/folia/purpur/spigot use `plugins`.
#
# All server config files (server.properties, bukkit.yml, spigot.yml, etc.)
# go through `serverFiles`. Mod config files go through `configFiles` (placed
# under config/).
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
  managedRoot = "/etc/minecraft";

  modCatalogType = types.submodule {
    options = {
      url = mkOption { type = types.str; };
      src = mkOption {
        type = types.path;
        description = "Locked mod artifact.";
      };
      pluginName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Runtime Bukkit plugin name, when it differs from the catalog slug.";
      };
    };
  };

  formatValueType = (pkgs.formats.json { }).type;

  modConfigType = types.submodule {
    freeformType = formatValueType;
  };

  pluginType = types.submodule {
    options = {
      src = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Plugin jar. Leave unset to resolve the plugin from pluginCatalog by slug.";
      };
      pluginName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Runtime Bukkit plugin name used by PlugManX reloads.";
      };
    };
  };

  modJars = lib.mapAttrsToList (
    slug: _:
    let
      entry = cfg.modCatalog.${slug} or (throw "mod '${slug}' not in modCatalog");
      pluginName =
        cfg.autoReload.plugman.pluginNames.${slug}
          or (if entry.pluginName == null then slug else entry.pluginName);
    in
    {
      name = "${slug}.jar";
      path = entry.src;
      inherit pluginName;
    }
  ) cfg.mods;

  pluginJars = lib.mapAttrsToList (
    slug: plugin:
    let
      entry =
        if plugin.src == null then
          cfg.pluginCatalog.${slug} or (throw "plugin '${slug}' not in pluginCatalog")
        else
          plugin;
      pluginName =
        cfg.autoReload.plugman.pluginNames.${slug}
          or (if entry.pluginName == null then slug else entry.pluginName);
    in
    {
      name = "${slug}.jar";
      path = entry.src;
      inherit pluginName;
    }
  ) cfg.plugins;

  loaderEnabled = {
    fabric = config.services.minecraft.fabric.enable;
    folia = config.services.minecraft.folia.enable;
    paper = config.services.minecraft.paper.enable;
    purpur = config.services.minecraft.purpur.enable;
    spigot = config.services.minecraft.spigot.enable;
    sponge = config.services.minecraft.sponge.enable;
  };

  bukkitLoaderEnabled = lib.any (name: loaderEnabled.${name}) [
    "folia"
    "paper"
    "purpur"
    "spigot"
  ];

  autoReloadDriver =
    if cfg.autoReload.driver != "auto" then
      cfg.autoReload.driver
    else if loaderEnabled.fabric then
      "jvm"
    else if bukkitLoaderEnabled then
      "plugman"
    else
      "none";

  autoReloadEnabled = cfg.autoReload.enable && autoReloadDriver != "none";
  jvmReloadEnabled = autoReloadEnabled && autoReloadDriver == "jvm";
  plugmanReloadEnabled = autoReloadEnabled && autoReloadDriver == "plugman";
  java = lib.getExe' cfg.javaPackage "java";
  pluginConfigFiles = lib.optionalAttrs plugmanReloadEnabled {
    "plugins/PlugManX/config.yml" = {
      ignored-plugins = cfg.autoReload.plugman.ignoredPlugins;
      notify-on-broken-command-removal = true;
      auto-load = {
        enabled = false;
        check-every-seconds = 10;
      };
      auto-unload = {
        enabled = false;
        check-every-seconds = 10;
      };
      auto-reload = {
        enabled = false;
        check-every-seconds = 10;
      };
      showPaperWarning = true;
      version = 3;
    };
  };

  managedJars =
    modJars
    ++ pluginJars
    ++ lib.optionals plugmanReloadEnabled [
      {
        name = "PlugManX.jar";
        path = ix.artifacts.minecraft.plugins.plugmanx;
        pluginName = "PlugManX";
      }
    ];

  managedDropins = pkgs.runCommand "minecraft-managed-${cfg.dropDir}" { } (
    ''
      mkdir -p "$out"
    ''
    + lib.concatMapStringsSep "\n" (jar: ''
      ln -s ${jar.path} "$out/${jar.name}"
      printf '%s\n' ${lib.escapeShellArg jar.pluginName} > "$out/${jar.name}.plugin-name"
    '') managedJars
  );

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
    .${ext} or (throw "configFiles: unsupported extension .${ext} on '${path}'");

  configLinks = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      path: value:
      let
        file = (formatFor path).generate (builtins.baseNameOf path) value;
      in
      "mkdir -p $out/${builtins.dirOf path}\nln -sf ${file} $out/${path}"
    ) cfg.configFiles
  );

  serverFiles = cfg.serverFiles // pluginConfigFiles;

  serverFileLinks = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      path: value:
      let
        file = (formatFor path).generate (builtins.baseNameOf path) value;
      in
      "mkdir -p $out/${builtins.dirOf path}\nln -sf ${file} $out/${path}"
    ) serverFiles
  );

  managedConfig = pkgs.runCommand "minecraft-managed-config" { } ''
    mkdir -p "$out"
    ${configLinks}
  '';

  managedServerFiles = pkgs.runCommand "minecraft-managed-server-files" { } ''
    mkdir -p "$out"
    ${serverFileLinks}
  '';

  syncManaged = ix.writeNushellApplication pkgs {
    name = "minecraft-sync-managed";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      const data_dir = ${builtins.toJSON dataDir}
      const drop_dir = ${builtins.toJSON cfg.dropDir}
      const managed_root = ${builtins.toJSON managedRoot}
      const plugman_reload = ${if plugmanReloadEnabled then "true" else "false"}
      const plugman_ignored_plugins = ${builtins.toJSON cfg.autoReload.plugman.ignoredPlugins}
      const rcon_port = ${toString cfg.autoReload.rconPort}
      const rcon_password_file = ${builtins.toJSON cfg.autoReload.rconPasswordFile}

      def managed-files [source_dir: string] {
        if not ($source_dir | path exists) {
          return []
        }

        do {
          cd $source_dir
          ^find . "(" -type f -o -type l ")" -print
          | lines
          | each { str replace --regex '^\./' "" }
          | where $it !~ '\.plugin-name$'
        }
      }

      def manifest-rel [line: string] {
        $line | split row " " | get 0
      }

      def sync-tree [source_dir: string, target_dir: string, manifest: string] {
        mkdir $target_dir ($manifest | path dirname)

        if ($manifest | path exists) {
          open --raw $manifest
          | lines
          | each { manifest-rel $in }
          | where $it != ""
          | each { rm --force $"($target_dir)/($in)" }
        }

        let tmp = $"($manifest).tmp"
        "" | save --force $tmp

        for rel in (managed-files $source_dir) {
          let source_path = $"($source_dir)/($rel)"
          mkdir ($"($target_dir)/($rel)" | path dirname)
          ln --symbolic --force --no-dereference $source_path $"($target_dir)/($rel)"
          let target = (^readlink -f $source_path | str trim)
          $"($rel) ($target)\n" | save --append $tmp
        }

        mv --force $tmp $manifest
      }

      def managed-target-for [manifest: string, rel: string] {
        if not ($manifest | path exists) {
          return null
        }

        let row = (
          open --raw $manifest
          | lines
          | where { |line| $line | str starts-with $"($rel) " }
          | get 0?
        )

        if $row == null {
          null
        } else {
          $row | split row " " | skip 1 | str join " "
        }
      }

      def plugin-name-for [rel: string] {
        let metadata = $"($managed_root)/managed-dropins/($rel).plugin-name"
        if ($metadata | path exists) {
          open --raw $metadata | lines | first
        } else {
          $rel | path parse | get stem
        }
      }

      def plugin-name-from-config-path [rel: string] {
        let parts = ($rel | split row "/")
        if (($parts | length) >= 3) and (($parts | first) == "plugins") {
          $parts | get 1
        } else {
          null
        }
      }

      def is-ignored-plugin [plugin: string] {
        $plugin in $plugman_ignored_plugins
      }

      def append-plan [plan: string, action: string, plugin: string] {
        $"($action) ($plugin)\n" | save --append $plan
      }

      def plan-plugman-reload [] {
        let dropin_manifest = $"($data_dir)/.ix-managed-($drop_dir)"
        let server_manifest = $"($data_dir)/.ix-managed-server-files"
        let plan = $"($data_dir)/.ix-managed-($drop_dir).reload-plan"
        "" | save --force $plan

        let managed_dropins = $"($managed_root)/managed-dropins"
        if ($dropin_manifest | path exists) and ($managed_dropins | path exists) {
          let jars = (
            do {
              cd $managed_dropins
              ^find . -maxdepth 1 "(" -type f -o -type l ")" -name "*.jar" "!" -name "*.plugin-name" -print
              | lines
              | each { str replace --regex '^\./' "" }
            }
          )

          for rel in $jars {
            if $rel == "PlugManX.jar" {
              continue
            }

            let target = (^readlink -f $"($managed_dropins)/($rel)" | str trim)
            let old_target = (managed-target-for $dropin_manifest $rel)
            let plugin = (plugin-name-for $rel)
            if (is-ignored-plugin $plugin) {
              continue
            }

            if $old_target == null {
              append-plan $plan load $plugin
            } else if $old_target != $target {
              append-plan $plan reload $plugin
            }
          }

          for line in (open --raw $dropin_manifest | lines) {
            let rel = (manifest-rel $line)
            if ($rel | str ends-with ".jar") and ($rel != "PlugManX.jar") {
              let plugin = (plugin-name-for $rel)
              if not (is-ignored-plugin $plugin) and not ($"($managed_dropins)/($rel)" | path exists) {
                append-plan $plan unload $plugin
              }
            }
          }
        }

        let managed_server_files = $"($managed_root)/managed-server-files"
        if ($server_manifest | path exists) and ($managed_server_files | path exists) {
          for rel in (managed-files $managed_server_files) {
            let plugin = (plugin-name-from-config-path $rel)
            if ($plugin == null) or (is-ignored-plugin $plugin) {
              continue
            }

            let target = (^readlink -f $"($managed_server_files)/($rel)" | str trim)
            let old_target = (managed-target-for $server_manifest $rel)
            if ($old_target == null) or ($old_target != $target) {
              append-plan $plan reload $plugin
            }
          }

          for line in (open --raw $server_manifest | lines) {
            let rel = (manifest-rel $line)
            let plugin = (plugin-name-from-config-path $rel)
            if ($plugin == null) or (is-ignored-plugin $plugin) {
              continue
            }

            if not ($"($managed_server_files)/($rel)" | path exists) {
              append-plan $plan reload $plugin
            }
          }
        }

        open --raw $plan | lines | sort | uniq | str join "\n" | save --force $plan
      }

      def ensure-rcon-password [] {
        mkdir ($rcon_password_file | path dirname)
        if not ($rcon_password_file | path exists) or ((open --raw $rcon_password_file | str trim | is-empty)) {
          let password = (^od -An -N32 -tx1 /dev/urandom | str replace --all " " "" | str trim)
          $"($password)\n" | save --force $rcon_password_file
          chmod 0600 $rcon_password_file
        }
      }

      def set-property [file: string, key: string, value: string] {
        let lines = if ($file | path exists) { open --raw $file | lines } else { [] }
        let replacement = $"($key)=($value)"
        let found = ($lines | any { |line| $line | str starts-with $"($key)=" })
        let next = (
          if $found {
            $lines | each { |line| if ($line | str starts-with $"($key)=") { $replacement } else { $line } }
          } else {
            $lines | append $replacement
          }
        )

        $next | str join "\n" | $"($in)\n" | save --force $file
      }

      def configure-rcon [] {
        ensure-rcon-password
        let server_properties = $"($data_dir)/server.properties"

        if ($server_properties | path type) == "symlink" {
          cp --force --dereference $server_properties $"($server_properties).tmp"
          mv --force $"($server_properties).tmp" $server_properties
        } else if not ($server_properties | path exists) {
          "" | save --force $server_properties
        }

        chmod 0600 $server_properties
        let password = (open --raw $rcon_password_file | lines | first)
        set-property $server_properties enable-rcon true
        set-property $server_properties rcon.port ($rcon_port | into string)
        set-property $server_properties rcon.password $password
        set-property $server_properties broadcast-rcon-to-ops false
      }

      def main [] {
        if $plugman_reload {
          plan-plugman-reload
        }

        sync-tree $"($managed_root)/managed-dropins" $"($data_dir)/($drop_dir)" $"($data_dir)/.ix-managed-($drop_dir)"
        sync-tree $"($managed_root)/managed-config" $"($data_dir)/config" $"($data_dir)/.ix-managed-config"
        sync-tree $"($managed_root)/managed-server-files" $data_dir $"($data_dir)/.ix-managed-server-files"

        if $plugman_reload {
          configure-rcon
        }
      }
    '';
  };

  reloadCommand = ix.writeNushellApplication pkgs {
    name = "minecraft-reload";
    runtimeInputs = [
      pkgs.minecraft-rcon
      syncManaged
    ];
    text = ''
      const driver = ${builtins.toJSON autoReloadDriver}
      const socket = ${builtins.toJSON cfg.autoReload.socketPath}
      const plan = ${builtins.toJSON "${dataDir}/.ix-managed-${cfg.dropDir}.reload-plan"}

      def main [] {
        minecraft-sync-managed

        match $driver {
          "jvm" => {
            if not (($socket | path type) == "socket") {
              print --stderr $"minecraft hot reload socket is not ready at ($socket); synced managed files only"
              return
            }

            exec ${java} -cp ${pkgs.minecraft-hot-reload-agent}/share/minecraft-hot-reload-agent/minecraft-hot-reload-agent.jar dev.ix.minecraft.hotreload.HotReloadAgent $socket redefine-dir ${managedRoot}/managed-dropins
          }
          "plugman" => {
            if not ($plan | path exists) or ((open --raw $plan | str trim | is-empty)) {
              return
            }

            mut failed = false
            for row in (open --raw $plan | lines | parse "{action} {plugin}") {
              if (do --ignore-errors {
                minecraft-rcon --host 127.0.0.1 --port ${toString cfg.autoReload.rconPort} --password-file ${builtins.toJSON cfg.autoReload.rconPasswordFile} plugman $row.action $row.plugin
              }) == null {
                $failed = true
              }
            }

            if $failed {
              exit 1
            }
          }
          "none" => {}
          _ => {
            print --stderr $"unsupported minecraft auto reload driver: ($driver)"
            exit 1
          }
        }
      }
    '';
  };

  autoReloadJvmFlags = lib.optionals jvmReloadEnabled [
    "-javaagent:${pkgs.minecraft-hot-reload-agent}/share/minecraft-hot-reload-agent/minecraft-hot-reload-agent.jar=socket=${cfg.autoReload.socketPath}"
    "-XX:+AllowEnhancedClassRedefinition"
  ];

  javaArgs = [
    java
    "-XX:MaxRAMPercentage=${toString cfg.maxRAMPercentage}"
  ]
  ++ cfg.jvmFlags
  ++ autoReloadJvmFlags
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
      description = "Subdirectory under the data dir where mod jars are symlinked. Loaders set this: fabric uses mods, paper uses plugins.";
    };

    maxRAMPercentage = mkOption {
      type = types.int;
      default = 85;
      description = "Max heap as a percentage of available system RAM. The JVM auto-scales to the VM's memory.";
    };

    mods = mkOption {
      type = types.attrsOf modConfigType;
      default = { };
      description = "Mods to install, keyed by Modrinth slug. Empty {} includes the jar with defaults. Attrsets with fields configure the mod (mod modules read these and generate config files).";
    };

    plugins = mkOption {
      type = types.attrsOf pluginType;
      default = { };
      description = "Bukkit-family plugins to install. Empty {} resolves a pinned catalog plugin by slug; attrsets with src install a local or private plugin jar.";
    };

    modCatalog = mkOption {
      type = types.attrsOf modCatalogType;
      default = { };
      description = "Slug to locked mod artifact mapping. Set by the image and version overlays from JSON catalogs generated by tools/update-mods.py and flake inputs.";
    };

    pluginCatalog = mkOption {
      type = types.attrsOf modCatalogType;
      default = { };
      description = "Slug to locked Bukkit plugin artifact mapping.";
    };

    javaPackage = mkOption {
      type = types.package;
      default = pkgs.temurin-jre-bin-25;
    };

    jvmFlags = mkOption {
      type = types.listOf types.str;
      default = [
        # Aikar's flags: https://mcflags.emc.gs
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+DisableExplicitGC" # prevent plugins from triggering full GC

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

    autoReload = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Reload managed mods/plugins during NixOS switch without restarting the Minecraft service when the active loader has a reload driver.";
      };

      driver = mkOption {
        type = types.enum [
          "auto"
          "jvm"
          "plugman"
          "none"
        ];
        default = "auto";
        description = "Reload driver. auto uses JVM class redefinition for Fabric and PlugManX for Bukkit-family loaders.";
      };

      socketPath = mkOption {
        type = types.str;
        default = "/run/minecraft-hot-reload/socket";
        description = "Unix-domain socket used by the JVM class redefinition agent.";
      };

      rconPort = mkOption {
        type = types.port;
        default = 25575;
        description = "Local RCON port used to ask PlugManX to reload Bukkit-family plugins.";
      };

      rconPasswordFile = mkOption {
        type = types.str;
        default = "${dataDir}/.ix-rcon-password";
        description = "State-local RCON password file used by the PlugManX reload command. Generated on first start when absent.";
      };

      plugman = {
        ignoredPlugins = mkOption {
          type = types.listOf types.str;
          default = [
            "PlugMan"
            "PlugManX"
            "PlugManBungee"
            "ViaVersion"
            "ViaBackwards"
            "ViaRewind"
            "ProtocolSupport"
            "ProtocolLib"
          ];
          description = "Plugins PlugManX should never manage during enable, disable, restart, load, reload, or unload operations.";
        };

        pluginNames = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Managed plugin slug to Bukkit plugin name mapping for PlugManX commands when the jar slug differs from the runtime plugin name.";
        };
      };
    };

    configFiles = mkOption {
      type = types.attrsOf formatValueType;
      default = { };
      description = "Config files to place under config/. Keys are relative paths (format inferred from extension: .toml, .json, .yaml, .yml, .properties). Values are Nix attrsets.";
    };

    serverFiles = mkOption {
      type = types.attrsOf formatValueType;
      default = { };
      description = "Files to place relative to the server root. Keys are paths (server.properties, bukkit.yml, etc.). Format inferred from extension.";
    };

    port = mkOption {
      type = types.port;
      default = 25565;
    };
  };

  config = mkIf cfg.enable {
    services.minecraft.serverFiles."server.properties".server-port = lib.mkDefault cfg.port;

    networking.firewall.allowedTCPPorts = [ cfg.port ];
    environment.etc."minecraft/managed-dropins".source = managedDropins;
    environment.etc."minecraft/managed-config".source = managedConfig;
    environment.etc."minecraft/managed-server-files".source = managedServerFiles;

    systemd.services.minecraft = {
      description = "Minecraft server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      reloadTriggers = lib.optionals autoReloadEnabled [
        managedDropins
        managedConfig
        managedServerFiles
      ];
      restartTriggers = lib.optionals (!autoReloadEnabled) [
        managedDropins
        managedConfig
        managedServerFiles
      ];
      serviceConfig = {
        Type = "simple";
        WorkingDirectory = dataDir;
        ExecStart = lib.escapeShellArgs javaArgs;
        ExecReload = lib.getExe reloadCommand;
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
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      }
      // lib.optionalAttrs jvmReloadEnabled {
        RuntimeDirectory = "minecraft-hot-reload";
      };
      preStart = ''
        mkdir -p ${dataDir}/${cfg.dropDir}
        echo "eula=true" > ${dataDir}/eula.txt
        ${lib.getExe syncManaged}
      '';
    };
  };
}
