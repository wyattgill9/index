# Minestom hello-world image.
#
# Builds a fat jar from ./project using Gradle inside Nix. Two phases:
# 1. gradleDeps (fixed-output derivation): downloads all Maven artifacts and
#    Gradle plugins. Network access is allowed because of outputHash. The
#    output hash only changes when dependencies change, not when Java source
#    changes.
# 2. serverJar (regular derivation): compiles the project offline using the
#    cached deps from phase 1.
{ lib, pkgs, ... }:
let
  jdk = pkgs.temurin-jdk-bin-25;

  # Phase 1: fetch all Gradle/Maven dependencies.
  gradleDeps = pkgs.stdenv.mkDerivation {
    __structuredAttrs = true;
    strictDeps = true;
    name = "minestom-hello-deps";
    src = ./project;

    nativeBuildInputs = [
      pkgs.gradle
      jdk
    ];

    buildPhase = ''
      export GRADLE_USER_HOME="$PWD/.gradle"
      export JAVA_HOME="${jdk}"
      gradle --no-daemon --console=plain dependencies buildEnvironment
    '';

    installPhase = ''
      find .gradle/caches -name "*.lock" -delete
      find .gradle -name "gc.properties" -delete
      mkdir -p "$out"
      cp -r .gradle/caches "$out/"
    '';

    outputHashMode = "recursive";
    outputHash = lib.fakeHash;
  };

  # Phase 2: compile offline, produce fat jar.
  serverJar = pkgs.stdenv.mkDerivation {
    __structuredAttrs = true;
    strictDeps = true;
    name = "minestom-hello";
    src = ./project;

    nativeBuildInputs = [
      pkgs.gradle
      jdk
    ];

    buildPhase = ''
      export GRADLE_USER_HOME="$PWD/.gradle"
      mkdir -p "$GRADLE_USER_HOME"
      cp -r ${gradleDeps}/caches "$GRADLE_USER_HOME/"
      chmod -R u+w "$GRADLE_USER_HOME"
      export JAVA_HOME="${jdk}"
      gradle --no-daemon --console=plain --offline shadowJar
    '';

    installPhase = ''
      cp build/libs/minestom-hello.jar "$out"
    '';
  };
in
{
  ix.image.name = "minestom-hello";

  services.minestom = {
    enable = true;
    serverJar = serverJar;
  };
}
