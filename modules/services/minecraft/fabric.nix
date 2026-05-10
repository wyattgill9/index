# Fabric server jar. https://fabricmc.net
# Pinned via the upstream meta API URL: minecraft version
# + Fabric loader version + Fabric installer version are all part of the URL.
{
  ix,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (ix.mkMinecraftLoader {
      inherit config lib pkgs;
      name = "fabric";
      dropDir = "mods";
      urlFor =
        cfg:
        "https://meta.fabricmc.net/v2/versions/loader/${cfg.version}/${cfg.loaderVersion}/${cfg.installerVersion}/server/jar";
      extraOptions = {
        version = lib.mkOption { type = lib.types.str; };
        loaderVersion = lib.mkOption { type = lib.types.str; };
        installerVersion = lib.mkOption { type = lib.types.str; };
      };
    })
  ];

  # Default the JVM to JetBrains Runtime (JBR) on Fabric. JBR is OpenJDK with
  # DCEVM (Dynamic Code Evolution VM) integrated, gated by the JBR-only
  # `-XX:+AllowEnhancedClassRedefinition` flag. With that flag plus a JDWP
  # debug agent attached, the JVM can redefine almost any structural class
  # change live: add/remove methods, add/remove fields, signature changes,
  # supertype changes. Stock OpenJDK can only swap method bodies, which
  # forces a full server restart for every other edit and is the main
  # iteration tax on Fabric mod work. Fabric is the loader where this
  # matters because mods are Java code (often Mixin-driven) that authors
  # recompile and reload during development; Paper/Spigot/etc. ship plugins
  # that don't benefit. Mixin authors additionally pass
  # `-javaagent:<sponge-mixin.jar>` to hot-swap mixin bodies; see the Fabric
  # docs link below.
  #
  # We do NOT set `-XX:+AllowEnhancedClassRedefinition` in `jvmFlags` here:
  # the flag is JBR-specific, so a future override of `javaPackage` back to
  # Temurin/OpenJDK would crash the JVM at startup. Devs enable it in their
  # own run config when iterating. JBR currently tracks Java 21, which
  # Minecraft 1.21+ already requires; other loaders keep the Temurin 25
  # default from `services.minecraft.javaPackage`.
  #
  # Refs:
  #   https://docs.fabricmc.net/develop/getting-started/launching-the-game#hotswapping-classes
  #   https://github.com/JetBrains/JetBrainsRuntime/issues/205
  config = lib.mkIf config.services.minecraft.fabric.enable {
    services.minecraft.javaPackage = lib.mkDefault pkgs.jetbrains.jdk-no-jcef;
  };
}
