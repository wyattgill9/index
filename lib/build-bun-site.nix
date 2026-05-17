{
  bunLockFor,
}:

/**
  Build a static frontend site from a Bun project.

  Dependency hashes come from `bun.lock`, so callers update dependencies with
  `bun install` and do not maintain a separate Nix dependency hash. Dependencies
  are built separately and linked into the site build, so source-only changes do
  not rerun `bun install`.

  Arguments:
  - `pname`, `version`: derivation identity.
  - `src`: project root containing `package.json` and `bun.lock`.
  - `buildScript`: Bun script to run for the production build.
  - `distDir`: relative path of the build output inside `src`.
  - `installDir`: path under `$out` where the built assets are installed.
  - `installFlags`: extra flags for `bun install` while building dependencies.
  - `extraNativeBuildInputs`: extra packages on PATH for the build.
  - `meta`: standard derivation meta.
*/
pkgs:
{
  pname,
  version ? "0.0.0",
  src,
  buildScript ? "build",
  distDir ? "dist",
  installDir ? "share/${pname}",
  installFlags ? [ ],
  extraNativeBuildInputs ? [ ],
  meta ? { },
}:
let
  bunLock = bunLockFor pkgs;
  bunNodeModules = bunLock.buildNodeModules {
    bunRoot = src;
    inherit installFlags;
    derivationArgs = {
      strictDeps = true;
    };
  };
in
pkgs.stdenvNoCC.mkDerivation (_: {
  inherit
    pname
    version
    src
    bunNodeModules
    meta
    ;

  strictDeps = true;

  nativeBuildInputs = [
    pkgs.bun
    bunLock.nodeCompat
  ]
  ++ extraNativeBuildInputs;

  configurePhase = ''
    runHook preConfigure

    patchShebangs .
    ln -s ${bunNodeModules}/node_modules node_modules
    export PATH="$PWD/node_modules/.bin:$PATH"

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    bun run ${buildScript}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/${installDir}"
    cp -R "${distDir}/." "$out/${installDir}/"
    runHook postInstall
  '';

  passthru = {
    inherit bunNodeModules;
  };
})
